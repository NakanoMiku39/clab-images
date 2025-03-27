#!/bin/bash

# 集群通知配置
CLAB_MASTER_IP="clab-notice.lcpu.dev"
CLAB_NOTIFICATIONS_URL="http://$CLAB_MASTER_IP/cluster_notifications"
CLAB_NOTIFICATIONS_CACHE_DIR="$HOME/.cluster_notifications"
CLAB_MAX_DISPLAY_COUNT=2
CLAB_MAX_AGE_DAYS=14

# 创建缓存目录
mkdir -p "$CLAB_NOTIFICATIONS_CACHE_DIR/notices"
# 确保display_counts.json存在并是有效的JSON
if [[ ! -f "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json" ]]; then
    echo "{}" > "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json"
fi

# 显示通知颜色配置
CLAB_COLOR_RED='\033[0;31m'
CLAB_COLOR_YELLOW='\033[0;33m'
CLAB_COLOR_GREEN='\033[0;32m'
CLAB_COLOR_BLUE='\033[0;34m'
CLAB_COLOR_NC='\033[0m' # No Color

# 获取并显示通知
function show_cluster_notifications {
    # 检查是否可以访问master服务器
    if ! curl -s --connect-timeout 3 "$CLAB_NOTIFICATIONS_URL/clab-notify.json" >/dev/null 2>&1; then
        return 0
    fi
    
    # 获取通知索引
    index_file="$CLAB_NOTIFICATIONS_CACHE_DIR/clab-notify.json"
    curl -s -o "$index_file" "$CLAB_NOTIFICATIONS_URL/clab-notify.json" 2>/dev/null
    
    if [[ ! -f "$index_file" ]]; then
        return 0
    fi
    
    # 确保显示计数文件存在且是有效的JSON
    if [[ ! -f "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json" ]]; then
        echo "{}" > "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json"
    fi
    
    # 读取通知列表
    mapfile -t notices < <(jq -r '.notices[]' "$index_file" 2>/dev/null)
    
    for notice_id in "${notices[@]}"; do
        # 获取通知文件
        notice_file="$CLAB_NOTIFICATIONS_CACHE_DIR/notices/$notice_id.json"
        curl -s -o "$notice_file" "$CLAB_NOTIFICATIONS_URL/$notice_id.json" 2>/dev/null
        
        if [[ ! -f "$notice_file" ]]; then
            continue
        fi
        
        # 解析通知内容
        title=$(jq -r '.title' "$notice_file")
        content=$(jq -r '.content' "$notice_file")
        severity=$(jq -r '.severity' "$notice_file")
        expiry_date=$(jq -r '.expiry_date' "$notice_file")
        
        # 检查是否过期
        current_date=$(date +%Y-%m-%d)
        if [[ "$expiry_date" < "$current_date" ]]; then
            rm -f "$notice_file"
            continue
        fi
        
        # 检查通知创建日期是否太早
        created_date=$(jq -r '.created_date' "$notice_file")
        days_old=$(( ( $(date -d "$current_date" +%s) - $(date -d "$created_date" +%s) ) / 86400 ))
        if [[ $days_old -gt $CLAB_MAX_AGE_DAYS ]]; then
            continue
        fi
        
        # 检查显示次数
        display_count=$(jq -r ".[\"$notice_id\"] // 0" "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json")
        
        if [[ $display_count -lt $CLAB_MAX_DISPLAY_COUNT ]]; then
            # 显示通知
            case "$severity" in
                critical)
                    color=$CLAB_COLOR_RED
                    ;;
                important)
                    color=$CLAB_COLOR_YELLOW
                    ;;
                info)
                    color=$CLAB_COLOR_BLUE
                    ;;
                *)
                    color=$CLAB_COLOR_GREEN
                    ;;
            esac
            
            echo -e "\n${color}========== CLab通知 ==========${CLAB_COLOR_NC}"
            echo -e "${color}标题:${CLAB_COLOR_NC} $title"
            echo -e "${color}内容:${CLAB_COLOR_NC} $content"
            echo -e "${color}过期日期:${CLAB_COLOR_NC} $expiry_date"
            echo -e "${color}============================${CLAB_COLOR_NC}\n"
            
            display_count=$((display_count + 1))
            
            tmp_file=$(mktemp)
            jq --arg id "$notice_id" --arg count "$display_count" '.[$id] = ($count|tonumber)' \
               "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json" > "$tmp_file"
               
            if [[ -s "$tmp_file" ]]; then
                mv "$tmp_file" "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json"
            else
                rm "$tmp_file"
                echo "{\"$notice_id\": $display_count}" > "$CLAB_NOTIFICATIONS_CACHE_DIR/display_counts.json"
            fi
        fi
    done
}

show_cluster_notifications