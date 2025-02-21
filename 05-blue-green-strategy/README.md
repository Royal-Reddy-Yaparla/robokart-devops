
# Blue-Green Deployment for Robokart Application

In a Blue-Green deployment strategy, two environments (Blue and Green) are used to deploy the application. The **Blue** environment represents the live, stable version, while the **Green** environment represents the new version being deployed. Once the Green environment is tested and verified, traffic is switched to the Green environment, making it the new live version. The Blue version can then be safely removed.

## Steps for Blue-Green Deployment

### Step 1: Deploy First Version (Blue)
The first version of the application is deployed under the name **`web`** and is mapped to the URL `robokart.royalreddy.site`. This is the stable version that is accessible by the end-users.

- **Service Name:** `web`
- **URL:** `robokart.royalreddy.site`
- **Version:** `1.0.0`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: robokart
  namespace: robokart
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/tags: Environment=dev,version=blue,Project=robokart
    alb.ingress.kubernetes.io/group.name: robokart
spec:
  ingressClassName: alb
  rules:
    - host: robokart.royalreddy.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
```

### Step 2: Deploy Second Version (Green)
Deploy the second version of the application under the name **`web-green`**. This version is mapped to the URL `green.royalreddy.site` and is used for testing purposes.

- **Service Name:** `web-green`
- **URL:** `green.royalreddy.site`
- **Version:** `2.0.0`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: robokart-green
  namespace: robokart
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/tags: Environment=dev,version=green,Project=robokart
    alb.ingress.kubernetes.io/group.name: robokart
spec:
  ingressClassName: alb
  rules:
    - host: green.royalreddy.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-green
                port:
                  number: 80
```

### Step 3: Testing the Green Version
After the second version (green) is deployed, the new version is tested thoroughly to ensure that everything works as expected.

- **URL for Testing:** `green.royalreddy.site`
- **Version Being Tested:** `2.0.0`

At this point, you can perform end-to-end tests and validate that the new version meets all requirements.

### Step 4: Switch Traffic to the Green Version
Once the green version is tested and verified, the traffic is switched from the **blue version** (`robokart.royalreddy.site`) to the **green version** (`robokartgreen.royalreddy.site`).

This is achieved by **updating the selectors** for the **first version’s (blue) service** (`web`) to point to the **second version’s (green) service** (`web-green`). As a result, traffic that was originally directed to the blue version (`web`) is now routed to the green version (`web-green`), and the green version becomes the live version.

#### Update the Service Selector for the Blue Version (Web):
1. **Before Update (Blue Version Service Selector)**:
   ```yaml
   selector:
     app: web
     version: 1.0.0
     project: robokart
   ```

2. **After Update (Blue Version Service Selector)** to Point to Green Version:
   ```yaml
   selector:
     app: web-green
     version: 2.0.0
     project: robokart
   ```

After this update, traffic will be directed to the green version under the URL `robokart.royalreddy.site`, replacing the blue version.

### Step 5: Clean Up the Blue Version
Once the green version is live and stable, the resources associated with the blue version can be deleted.

This will free up resources and clean up any unused components related to the old deployment.

---

## Benefits of Blue-Green Deployment
- **Zero Downtime:** By switching traffic between the two versions, the new version can be fully tested and validated before switching over, ensuring there is no downtime.
- **Easy Rollback:** If any issues arise after switching to the green version, you can quickly roll back to the blue version.
- **Efficient Resource Usage:** Old versions are cleaned up after successful deployment, ensuring resources are efficiently used.

---

## Conclusion

Blue-Green deployments allow for smooth application upgrades with zero downtime and minimal risk. By using this approach, you can seamlessly deploy new versions of your application while ensuring that users always have access to a stable version.

---

### Key Points:
- **First Version (Blue)** is live and mapped to `robokart.royalreddy.site`.
- **Second Version (Green)** is tested and mapped to `green.royalreddy.site`.
- After testing, the selectors of the **blue version** are updated to point to the **green version**.
- The **green version** becomes live, and the **blue version** resources are deleted.

