# Use Python 3.11 slim image as base with platform specification
FROM --platform=linux/amd64 python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    python3-dev \
    musl-dev \
    libpq-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy project
COPY . /app/

# Create necessary directories
RUN mkdir -p /app/media/post_images /app/staticfiles

# Create entrypoint script
RUN echo '#!/bin/sh\n\
python manage.py migrate\n\
python manage.py collectstatic --noinput\n\
gunicorn --bind 0.0.0.0:8000 --workers 2 backend.wsgi:application' > /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# Run the application
EXPOSE 8000
CMD ["/app/entrypoint.sh"]