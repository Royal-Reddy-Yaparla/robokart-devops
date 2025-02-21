FROM python:3.9.18-alpine3.19

EXPOSE 8080
ENV AMQP_USER=roboshop \
    AMQP_PASS=roboshop123

USER root
WORKDIR /app

# Copy requirements file
COPY requirements.txt /app/

# Update and install necessary packages using apk
RUN apk add --no-cache \
    python3-dev \
    build-base \
    linux-headers \
    pcre-dev

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY *.py /app/
COPY payment.ini /app/

# Default command
CMD ["python", "payment.py"]
