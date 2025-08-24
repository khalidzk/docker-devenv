#!/bin/bash

# 设置密码
REDIS_PASSWORD="123456"

# 节点列表
NODES=(
  "172.202.0.2:6379"
  "172.202.0.3:6380"
  "172.202.0.4:6381"
  "172.202.0.5:6382"
  "172.202.0.6:6383"
  "172.202.0.7:6384"
)

echo "等待Redis节点启动..."

# 等待所有节点就绪
for node in "${NODES[@]}"; do
  IFS=':' read -r ip port <<< "$node"
  until redis-cli -h "$ip" -p "$port" -a "$REDIS_PASSWORD" ping | grep -q "PONG"; do
    echo "等待节点 $node 就绪..."
    sleep 2
  done
  echo "节点 $node 已就绪"
done

echo "所有节点已就绪，开始创建集群..."

# 尝试创建集群
if redis-cli --cluster create \
    "${NODES[0]}" \
    "${NODES[1]}" \
    "${NODES[2]}" \
    "${NODES[3]}" \
    "${NODES[4]}" \
    "${NODES[5]}" \
    --cluster-replicas 1 \
    --cluster-yes \
    -a "$REDIS_PASSWORD"; then
  echo "Redis集群创建成功!"
  exit 0
else
  echo "Redis集群创建失败，检查是否已存在集群..."
  
  # 检查集群状态
  if redis-cli -h "${NODES[0]%:*}" -p "${NODES[0]#*:}" -a "$REDIS_PASSWORD" cluster info | grep -q 'cluster_state:ok'; then
    echo "集群已存在，初始化完成"
    exit 0
  else
    echo "集群未正确创建，请检查节点状态"
    exit 1
  fi
fi