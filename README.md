# terraform-controller-modules

K8S setup

1. Secret:
```
echo -e "gcpCredentialsJSON: '${GOOGLE_CREDENTIALS}'\ngcpProject: ${GOOGLE_PROJECT}" > gcp-credentials.conf
kubectl create secret generic gcp-account-creds-project-test -n katee-engineering-enablement --from-file=credentials=gcp-credentials.conf
rm -f gcp-credentials.conf
```

2. Provider pointing to the secret: `kubectl -n katee-engineering-enablement apply -f provider.yaml`

3. Component `kubectl -n katee-engineering-enablement apply -f cloudrun.yaml`

4. Application

