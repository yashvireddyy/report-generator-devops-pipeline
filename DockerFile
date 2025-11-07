# ===========================================================
# Dockerfile: Report Generator Container
# ===========================================================

# Base image with Python
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# ---------------------------------------------------------s
# Install dependencies
# -----------------------------------------------------------
# Install essential system packages and AWS CLI
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    curl \
    less \
    groff \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# -----------------------------------------------------------
# Copy project files into container
# -----------------------------------------------------------
COPY report_generator.py .
COPY style.css .

# -----------------------------------------------------------
# Install Python libraries
# -----------------------------------------------------------
RUN pip install --no-cache-dir \
    pandas \
    matplotlib \
    boto3

# -----------------------------------------------------------
# Create output folder
# -----------------------------------------------------------
RUN mkdir -p /app/reports

# -----------------------------------------------------------
# Default command to run the report generator
# -----------------------------------------------------------
CMD ["python", "report_generator.py"]
