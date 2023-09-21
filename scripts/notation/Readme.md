# Notation scripts info

## Execution order

1. add image to registry

    ```bash
    ./notation-add-image-to-local-registry.sh
    ```

2. Generate a test key and self-signed certificate

    ```bash
    ./notation-create-cert-self-signed.sh
    ```

3. Verify container image

    ```bash
    ./notation-sign-image.sh
    ```

4. Create a trust policy to verify against

    ```bash
    notation-import-trust-policy.sh
    ```

5. Verify the image

    ```bash
    ./notation-verify-image.sh
    ```
