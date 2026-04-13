# Assignment Dockerfile: build tag example →  docker build -t my-python-app:v1 .
FROM python:3.12-slim

# Inside Docker the install runs as root; this silences pip’s generic “don’t use root” warning.
ENV PIP_ROOT_USER_ACTION=ignore

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
