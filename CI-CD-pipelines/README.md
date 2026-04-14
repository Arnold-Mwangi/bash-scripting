# CI/CD Checkpoint

This README documents my class checkpoint implementation for GitLab CI/CD using my existing Spring Boot project (`rekon`) so the setup is reproducible and verifiable.


## Checkpoint Objectives

This submission demonstrates:

1. GitLab project setup and initial `.gitlab-ci.yml` pipeline
2. Understanding of pipeline stages, jobs, and runner behavior
3. Pipeline log review and environment variable visibility
4. Dockerfile creation and automated image build/push via CI
5. Artifact creation and retention in GitLab CI/CD

## Task 1 - Create Project

I Imported a github project for CI/CD work (public visibility) and initialized it with a README.
** project link ** -- https://gitlab.com/arnoldkirigwi/rekon/

- Group/project created in GitLab
- Repository initialized
- Local code connected to GitLab remote

## Task 2 - Add `.gitlab-ci.yml`

Pipeline file is present and functional in the `rekon` repository root.

- Project reference: `/home/kirigwi/Development/clarity/rekon`
- Pipeline file used: `/home/kirigwi/Development/clarity/rekon/.gitlab-ci.yml`

Baseline example from class:

```yaml
stages:
  - build
  - test

build1:
  stage: build
  script:
    - echo "Do your build here"

test1:
  stage: test
  script:
    - echo "Do a test here"
    - echo "For example run a test suite"
```

My actual implementation in `rekon` uses real jobs (`test`, `build image`) and artifact outputs, not only echo examples.

## Task 3 - Pipeline Status, Stages, Jobs, Runner

I validated pipelines in GitLab:

- Opened **Build > Pipelines**
- Opened latest pipeline details
- Confirmed stage columns and job execution order
- Opened job logs and verified runner metadata at top of logs
- Confirmed Docker-based runner executes jobs

## Task 4 - View Environment Variables

I used/verified a debug job to inspect runner environment context:

```yaml
environment echoes:
  stage: build
  script:
    - echo "Who am I running as..."
    - whoami
    - echo "Where am I..."
    - pwd
    - ls -al
    - echo "Here's what is available in our environment..."
    - env
```

Observed variables include GitLab CI defaults (for example `CI_PROJECT_DIR`, `CI_COMMIT_SHA`, `CI_REGISTRY`, `CI_REGISTRY_IMAGE`).

## Task 5 - Dockerfile and Build Image Job

### Dockerfile

The project includes a functional Dockerfile at `/home/kirigwi/Development/clarity/rekon/Dockerfile` for application image creation.

Class sample Dockerfile (Go) reference:

```dockerfile
FROM golang:1.11-alpine as builder
WORKDIR /usr/build
ADD main.go .
RUN go build -o app .
FROM alpine:latest
WORKDIR /usr/src
COPY --from=builder /usr/build/app .
EXPOSE 8080
CMD ["/usr/src/app"]
```

Actual Dockerfile used for my submission is from the `rekon` Spring Boot project (Java 17, multi-stage build).

### Build and Push in CI

The pipeline includes a Docker image job in `rekon/.gitlab-ci.yml` that follows the class requirement to build and push to GitLab registry:

```yaml
build image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    IMAGE: "$CI_REGISTRY_IMAGE:${CI_COMMIT_REF_SLUG}-${CI_COMMIT_SHORT_SHA}"
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

This is the script I used (with `--password-stdin` for secure login).

### Registry Verification

After successful pipeline run:
- I checked **Deploy > Container Registry**
- Confirmed image tag was pushed successfully

## Task 6 - Artifacts

Artifacts are generated and retained by pipeline jobs.

Class sample artifact job:

```yaml
build app:
  image: golang:latest
  stage: build
  script:
    - go build -o app main.go
  artifacts:
    paths:
      - app
    expire_in: 1 hour
```

In my project, artifacts include:
- JUnit test reports
- Test report directories
- Image metadata artifact (`image.env`)

Retention is configured in `rekon/.gitlab-ci.yml` (currently one week for key jobs).

## Required Submission Deliverables Checklist

- [x] Functional `.gitlab-ci.yml` with build/test/image/artifact behavior
- [x] Dockerfile used for container image builds
- [x] Source code used by pipeline jobs
- [x] Any referenced scripts/files committed in repository
- [x] Environment variable usage documented
- [x] GitLab Container Registry image successfully pushed
- [ ] Screenshots attached for:
  - [ ] Successful pipeline run list
  - [ ] Job logs (build/test/image stages)
  - [ ] Artifacts panel showing downloadable outputs
  - [ ] Container Registry image listing

## Evidence Storage in This Folder

Store class evidence files in:

- `images/` (pipeline and registry screenshots)
- `artifacts/` (exported logs, downloaded artifacts, notes)

## Attached activity Screenshots

### 1) Successful pipeline execution

![Successful pipeline execution](images/successful%20pipeline%20execution.png)

### 2) Test job logs

![Test job](images/test%20job.png)

### 3) Build image job logs

![Build image job](images/build%20image%20job.png)

### 4) Container Registry image listing

![Container images from registry](images/container%20images%20from%20registry.png)

## Runner and Registry Notes

- Runner executor is Docker (isolated per job).
- Registry login uses GitLab credentials/tokens, not Docker Hub credentials.
- If 2FA is enabled, use GitLab token scopes (`read_registry`, `write_registry`) instead of account password.

## Future Improvement

Next enhancement planned: add a Kubernetes deployment stage after successful image build and push.
# CI/CD Checkpoint

This README documents my class checkpoint implementation for GitLab CI/CD using my existing Spring Boot project (`rekon`) so the setup is reproducible and verifiable.


## Checkpoint Objectives

This submission demonstrates:

1. GitLab project setup and initial `.gitlab-ci.yml` pipeline
2. Understanding of pipeline stages, jobs, and runner behavior
3. Pipeline log review and environment variable visibility
4. Dockerfile creation and automated image build/push via CI
5. Artifact creation and retention in GitLab CI/CD

## Task 1 - Create Project

I Imported a github project for CI/CD work (public visibility) and initialized it with a README.

- Group/project created in GitLab
- Repository initialized
- Local code connected to GitLab remote

## Task 2 - Add `.gitlab-ci.yml`

Pipeline file is present and functional in the `rekon` repository root.

- Project reference: `/home/kirigwi/Development/clarity/rekon`
- Pipeline file used: `/home/kirigwi/Development/clarity/rekon/.gitlab-ci.yml`

Baseline example from class:

```yaml
stages:
  - build
  - test

build1:
  stage: build
  script:
    - echo "Do your build here"

test1:
  stage: test
  script:
    - echo "Do a test here"
    - echo "For example run a test suite"
```

My actual implementation in `rekon` uses real jobs (`test`, `build image`) and artifact outputs, not only echo examples.

## Task 3 - Pipeline Status, Stages, Jobs, Runner

I validated pipelines in GitLab:

- Opened **Build > Pipelines**
- Opened latest pipeline details
- Confirmed stage columns and job execution order
- Opened job logs and verified runner metadata at top of logs
- Confirmed Docker-based runner executes jobs

## Task 4 - View Environment Variables

I used/verified a debug job to inspect runner environment context:

```yaml
environment echoes:
  stage: build
  script:
    - echo "Who am I running as..."
    - whoami
    - echo "Where am I..."
    - pwd
    - ls -al
    - echo "Here's what is available in our environment..."
    - env
```

Observed variables include GitLab CI defaults (for example `CI_PROJECT_DIR`, `CI_COMMIT_SHA`, `CI_REGISTRY`, `CI_REGISTRY_IMAGE`).

## Task 5 - Dockerfile and Build Image Job

### Dockerfile

The project includes a functional Dockerfile at `/home/kirigwi/Development/clarity/rekon/Dockerfile` for application image creation.

Class sample Dockerfile (Go) reference:

```dockerfile
FROM golang:1.11-alpine as builder
WORKDIR /usr/build
ADD main.go .
RUN go build -o app .
FROM alpine:latest
WORKDIR /usr/src
COPY --from=builder /usr/build/app .
EXPOSE 8080
CMD ["/usr/src/app"]
```

Actual Dockerfile used for my submission is from the `rekon` Spring Boot project (Java 17, multi-stage build).

### Build and Push in CI

The pipeline includes a Docker image job in `rekon/.gitlab-ci.yml` that follows the class requirement to build and push to GitLab registry:

```yaml
build image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    IMAGE: "$CI_REGISTRY_IMAGE:${CI_COMMIT_REF_SLUG}-${CI_COMMIT_SHORT_SHA}"
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

This is the script I used (with `--password-stdin` for secure login).

### Registry Verification

After successful pipeline run:
- I checked **Deploy > Container Registry**
- Confirmed image tag was pushed successfully

## Task 6 - Artifacts

Artifacts are generated and retained by pipeline jobs.

Class sample artifact job:

```yaml
build app:
  image: golang:latest
  stage: build
  script:
    - go build -o app main.go
  artifacts:
    paths:
      - app
    expire_in: 1 hour
```

In my project, artifacts include:
- JUnit test reports
- Test report directories
- Image metadata artifact (`image.env`)

Retention is configured in `rekon/.gitlab-ci.yml` (currently one week for key jobs).

## Required Submission Deliverables Checklist

- [x] Functional `.gitlab-ci.yml` with build/test/image/artifact behavior
- [x] Dockerfile used for container image builds
- [x] Source code used by pipeline jobs
- [x] Any referenced scripts/files committed in repository
- [x] Environment variable usage documented
- [x] GitLab Container Registry image successfully pushed
- [ ] Screenshots attached for:
  - [ ] Successful pipeline run list
  - [ ] Job logs (build/test/image stages)
  - [ ] Artifacts panel showing downloadable outputs
  - [ ] Container Registry image listing

## Evidence Storage in This Folder

Store class evidence files in:

- `images/` (pipeline and registry screenshots)
- `artifacts/` (exported logs, downloaded artifacts, notes)

## Attached activity Screenshots

### 1) Successful pipeline execution

![Successful pipeline execution](images/successful%20pipeline%20execution.png)

### 2) Test job logs

![Test job](images/test%20job.png)

### 3) Build image job logs

![Build image job](images/build%20image%20job.png)

### 4) Container Registry image listing

![Container images from registry](images/container%20images%20from%20registry.png)

## Runner and Registry Notes

- Runner executor is Docker (isolated per job).
- Registry login uses GitLab credentials/tokens, not Docker Hub credentials.
- If 2FA is enabled, use GitLab token scopes (`read_registry`, `write_registry`) instead of account password.

## Future Improvement

Next enhancement planned: add a Kubernetes deployment stage after successful image build and push.
# CI/CD Checkpoint

This README documents my class checkpoint implementation for GitLab CI/CD using my existing Spring Boot project (`rekon`) so the setup is reproducible and verifiable.


## Checkpoint Objectives

This submission demonstrates:

1. GitLab project setup and initial `.gitlab-ci.yml` pipeline
2. Understanding of pipeline stages, jobs, and runner behavior
3. Pipeline log review and environment variable visibility
4. Dockerfile creation and automated image build/push via CI
5. Artifact creation and retention in GitLab CI/CD

## Task 1 - Create Project

I Imported a github project for CI/CD work (public visibility) and initialized it with a README.

- Group/project created in GitLab
- Repository initialized
- Local code connected to GitLab remote

## Task 2 - Add `.gitlab-ci.yml`

Pipeline file is present and functional in the `rekon` repository root.

- Project reference: `/home/kirigwi/Development/clarity/rekon`
- Pipeline file used: `/home/kirigwi/Development/clarity/rekon/.gitlab-ci.yml`

Baseline example from class:

```yaml
stages:
  - build
  - test

build1:
  stage: build
  script:
    - echo "Do your build here"

test1:
  stage: test
  script:
    - echo "Do a test here"
    - echo "For example run a test suite"
```

My actual implementation in `rekon` uses real jobs (`test`, `build image`) and artifact outputs, not only echo examples.

## Task 3 - Pipeline Status, Stages, Jobs, Runner

I validated pipelines in GitLab:

- Opened **Build > Pipelines**
- Opened latest pipeline details
- Confirmed stage columns and job execution order
- Opened job logs and verified runner metadata at top of logs
- Confirmed Docker-based runner executes jobs

## Task 4 - View Environment Variables

I used/verified a debug job to inspect runner environment context:

```yaml
environment echoes:
  stage: build
  script:
    - echo "Who am I running as..."
    - whoami
    - echo "Where am I..."
    - pwd
    - ls -al
    - echo "Here's what is available in our environment..."
    - env
```

Observed variables include GitLab CI defaults (for example `CI_PROJECT_DIR`, `CI_COMMIT_SHA`, `CI_REGISTRY`, `CI_REGISTRY_IMAGE`).

## Task 5 - Dockerfile and Build Image Job

### Dockerfile

The project includes a functional Dockerfile at `/home/kirigwi/Development/clarity/rekon/Dockerfile` for application image creation.

Class sample Dockerfile (Go) reference:

```dockerfile
FROM golang:1.11-alpine as builder
WORKDIR /usr/build
ADD main.go .
RUN go build -o app .
FROM alpine:latest
WORKDIR /usr/src
COPY --from=builder /usr/build/app .
EXPOSE 8080
CMD ["/usr/src/app"]
```

Actual Dockerfile used for my submission is from the `rekon` Spring Boot project (Java 17, multi-stage build).

### Build and Push in CI

The pipeline includes a Docker image job in `rekon/.gitlab-ci.yml` that follows the class requirement to build and push to GitLab registry:

```yaml
build image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    IMAGE: "$CI_REGISTRY_IMAGE:${CI_COMMIT_REF_SLUG}-${CI_COMMIT_SHORT_SHA}"
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

This is the script I used (with `--password-stdin` for secure login).

### Registry Verification

After successful pipeline run:
- I checked **Deploy > Container Registry**
- Confirmed image tag was pushed successfully

## Task 6 - Artifacts

Artifacts are generated and retained by pipeline jobs.

Class sample artifact job:

```yaml
build app:
  image: golang:latest
  stage: build
  script:
    - go build -o app main.go
  artifacts:
    paths:
      - app
    expire_in: 1 hour
```

In my project, artifacts include:
- JUnit test reports
- Test report directories
- Image metadata artifact (`image.env`)

Retention is configured in `rekon/.gitlab-ci.yml` (currently one week for key jobs).

## Required Submission Deliverables Checklist

- [x] Functional `.gitlab-ci.yml` with build/test/image/artifact behavior
- [x] Dockerfile used for container image builds
- [x] Source code used by pipeline jobs
- [x] Any referenced scripts/files committed in repository
- [x] Environment variable usage documented
- [x] GitLab Container Registry image successfully pushed
- [ ] Screenshots attached for:
  - [ ] Successful pipeline run list
  - [ ] Job logs (build/test/image stages)
  - [ ] Artifacts panel showing downloadable outputs
  - [ ] Container Registry image listing

## Evidence Storage in This Folder

Store class evidence files in:

- `images/` (pipeline and registry screenshots)
- `artifacts/` (exported logs, downloaded artifacts, notes)

## Attached activity Screenshots

### 1) Successful pipeline execution

![Successful pipeline execution](images/successful%20pipeline%20execution.png)

### 2) Test job logs

![Test job](images/test%20job.png)

### 3) Build image job logs

![Build image job](images/build%20image%20job.png)

### 4) Container Registry image listing

![Container images from registry](images/container%20images%20from%20registry.png)

## Runner and Registry Notes

- Runner executor is Docker (isolated per job).
- Registry login uses GitLab credentials/tokens, not Docker Hub credentials.
- If 2FA is enabled, use GitLab token scopes (`read_registry`, `write_registry`) instead of account password.

## Future Improvement

Next enhancement planned: add a Kubernetes deployment stage after successful image build and push.
