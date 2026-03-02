#!/bin/bash
set -euo pipefail

REGION="${1:-us-east-1}"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
CPU_IDLE=$(top -bn1 | awk '/Cpu\(s\)/ {print $8}')
MEM_USED_PERCENT=$(free | awk '/Mem:/ {printf("%.2f", ($3/$2) * 100)}')

aws cloudwatch put-metric-data \
  --region "$REGION" \
  --namespace "Custom/EC2" \
  --metric-name "MemoryUtilization" \
  --dimensions InstanceId="$INSTANCE_ID" \
  --value "$MEM_USED_PERCENT" \
  --unit Percent

aws cloudwatch put-metric-data \
  --region "$REGION" \
  --namespace "Custom/EC2" \
  --metric-name "CPUIdle" \
  --dimensions InstanceId="$INSTANCE_ID" \
  --value "$CPU_IDLE" \
  --unit Percent
