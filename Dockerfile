FROM ubuntu:22.04

# Install required packages
RUN apt-get update && \
    apt-get install -y curl procps && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy script into container
COPY health-check.sh .

# Make script executable
RUN chmod +x health-check.sh

# Default command
CMD ["./health-check.sh"]

HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
  CMD bash -c 'test -f /tmp/last_check && \
  [ $(( $(date +%s) - $(cat /tmp/last_check) )) -lt 600 ]'
