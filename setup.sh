#!/usr/bin/env bash

export PROJECT_ID=$(gcloud config get-value project)

gcloud services enable iam.googleapis.com sts.googleapis.com iamcredentials.googleapis.com \
--project $PROJECT_ID

gcloud iam service-accounts create "my-service-account" \
--project "${PROJECT_ID}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member "serviceAccount:my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
--role "roles/storage.objectAdmin"

# secrets manager and disk create
gcloud services enable secretmanager.googleapis.com \
--project $PROJECT_ID
gcloud secrets create "my-secret" --replication-policy="automatic"
echo "hello-whirled" >> hello.txt
gcloud secrets versions add "my-secret" --data-file="hello.txt"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member "serviceAccount:my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
--role "roles/secretmanager.secretAccessor"

gcloud services enable compute.googleapis.com \
--project $PROJECT_ID
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member "serviceAccount:my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
--role "roles/compute.storageAdmin"

gsutil mb gs://gwc-wif-terraform-state
# end

gcloud iam workload-identity-pools create "my-pool" \
--project="${PROJECT_ID}" \
--location="global" \
--display-name="Demo pool"

gcloud iam workload-identity-pools describe "my-pool" \
--project="${PROJECT_ID}" \
--location="global" \
--format="value(name)"

export WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "my-pool" \
    --project="${PROJECT_ID}" \
    --location="global" \
--format="value(name)")

gcloud iam workload-identity-pools providers create-oidc "my-provider" \
--project="${PROJECT_ID}" \
--location="global" \
--workload-identity-pool="my-pool" \
--display-name="Demo provider" \
--attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
--issuer-uri="https://token.actions.githubusercontent.com"

# TODO(developer): Update this value to your GitHub repository.
export REPO="garrettwong/auth" # e.g. "google/chrome"

gcloud iam service-accounts add-iam-policy-binding "my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
--project="${PROJECT_ID}" \
--role="roles/iam.workloadIdentityUser" \
--member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"

gcloud iam workload-identity-pools providers describe "my-provider" \
--project="${PROJECT_ID}" \
--location="global" \
--workload-identity-pool="my-pool" \
--format="value(name)"


PROJECT_NUMBER=$(gcloud projects list --filter="projectId=${PROJECT_ID}" --format="value(projectNumber)")

echo "PROJECT_NUMBER: ${PROJECT_NUMBER}"