#!/bin/bash

echo "🛑 Stopping LocalStack version of Lambda CI/CD Sample..."

# すべてのサービスを停止
docker-compose down --remove-orphans

# 未使用のDockerリソースをクリーンアップ（オプション）
echo "Cleaning up Docker resources..."
docker system prune -f

echo "✅ All services stopped and cleaned up!"