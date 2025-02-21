import instana
import os
import sys
import time
import logging
import uuid
import json
import requests
import traceback
import opentracing as ot
import opentracing.ext.tags as tags
from flask import Flask, Response, request, jsonify
from rabbitmq import Publisher
import prometheus_client
from prometheus_client import Counter, Histogram

app = Flask(__name__)
app.logger.setLevel(logging.INFO)

CART = os.getenv('CART_HOST', 'cart')
CART_PORT = os.getenv('CART_PORT', 8080)
USER = os.getenv('USER_HOST', 'user')
USER_PORT = os.getenv('USER_PORT', 8080)
PAYMENT_GATEWAY = os.getenv('PAYMENT_GATEWAY', 'https://google.com/')

# Prometheus metrics
PromMetrics = {
    'SOLD_COUNTER': Counter('sold_count', 'Running count of items sold'),
    'AUS': Histogram('units_sold', 'Average Unit Sale', buckets=(1, 2, 5, 10, 100)),
    'AVS': Histogram('cart_value', 'Average Value Sale', buckets=(100, 200, 500, 1000, 2000, 5000, 10000))
}

@app.errorhandler(Exception)
def exception_handler(err):
    app.logger.error(str(err))
    return str(err), 500

@app.route('/health', methods=['GET'])
def health():
    return 'OK'

# Prometheus metrics endpoint
@app.route('/metrics', methods=['GET'])
def metrics():
    res = [prometheus_client.generate_latest(m) for m in PromMetrics.values()]
    return Response(res, mimetype='text/plain')

@app.route('/pay/<id>', methods=['POST'])
def pay(id):
    app.logger.info('payment for {}'.format(id))
    cart = request.get_json()
    app.logger.info(cart)

    anonymous_user = True

    # Add some log info to the active trace
    span = ot.tracer.active_span
    if span:
        span.log_kv({'id': id, 'cart': cart})

    # Check if user exists
    try:
        req = requests.get(f'http://{USER}:{USER_PORT}/check/{id}')
        if req.status_code == 200:
            anonymous_user = False
    except requests.exceptions.RequestException as err:
        app.logger.error(err)
        return str(err), 500

    # Validate cart
    has_shipping = any(item.get('sku') == 'SHIP' for item in cart.get('items', []))
    if cart.get('total', 0) == 0 or not has_shipping:
        app.logger.warning('cart not valid')
        return 'cart not valid', 400

    # Dummy call to payment gateway
    try:
        req = requests.get(PAYMENT_GATEWAY)
        app.logger.info('{} returned {}'.format(PAYMENT_GATEWAY, req.status_code))
        if req.status_code != 200:
            return 'payment error', req.status_code
    except requests.exceptions.RequestException as err:
        app.logger.error(err)
        return str(err), 500

    # Prometheus metrics
    item_count = countItems(cart.get('items', []))
    PromMetrics['SOLD_COUNTER'].inc(item_count)
    PromMetrics['AUS'].observe(item_count)
    PromMetrics['AVS'].observe(cart.get('total', 0))

    # Generate order id and queue order
    orderid = str(uuid.uuid4())
    queueOrder({'orderid': orderid, 'user': id, 'cart': cart})

    # Add to order history if user is not anonymous
    if not anonymous_user:
        try:
            req = requests.post(f'http://{USER}:{USER_PORT}/order/{id}', 
                                data=json.dumps({'orderid': orderid, 'cart': cart}),
                                headers={'Content-Type': 'application/json'})
            app.logger.info('order history returned {}'.format(req.status_code))
        except requests.exceptions.RequestException as err:
            app.logger.error(err)
            return str(err), 500

    # Delete cart
    try:
        req = requests.delete(f'http://{CART}:{CART_PORT}/cart/{id}')
        app.logger.info('cart delete returned {}'.format(req.status_code))
        if req.status_code != 200:
            return 'order history update error', req.status_code
    except requests.exceptions.RequestException as err:
        app.logger.error(err)
        return str(err), 500

    return jsonify({'orderid': orderid})

def queueOrder(order):
    app.logger.info('queue order')

    parent_span = ot.tracer.active_span
    with ot.tracer.start_active_span('queueOrder', child_of=parent_span,
                                     tags={'exchange': Publisher.EXCHANGE, 'key': Publisher.ROUTING_KEY}) as tscope:
        tscope.span.set_tag('span.kind', 'intermediate')
        tscope.span.log_kv({'orderid': order.get('orderid')})
        with ot.tracer.start_active_span('rabbitmq', child_of=tscope.span,
                                         tags={'exchange': Publisher.EXCHANGE, 'sort': 'publish', 'address': Publisher.HOST, 'key': Publisher.ROUTING_KEY}) as scope:

            # Optionally add delay for demo requirements
            delay = int(os.getenv('PAYMENT_DELAY_MS', 0))
            time.sleep(delay / 1000)

            headers = {}
            ot.tracer.inject(scope.span.context, ot.Format.HTTP_HEADERS, headers)
            app.logger.info('msg headers {}'.format(headers))

            publisher.publish(order, headers)

def countItems(items):
    return sum(item.get('qty', 0) for item in items if item.get('sku') != 'SHIP')

# Initialize RabbitMQ publisher
publisher = Publisher(app.logger)

if __name__ == "__main__":
    sh = logging.StreamHandler(sys.stdout)
    sh.setLevel(logging.INFO)
    fmt = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    app.logger.info('Payment gateway {}'.format(PAYMENT_GATEWAY))
    port = int(os.getenv("SHOP_PAYMENT_PORT", "8080"))
    app.logger.info('Starting on port {}'.format(port))
    app.run(host='0.0.0.0', port=port)
