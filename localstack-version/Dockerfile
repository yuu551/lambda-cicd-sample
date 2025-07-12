FROM public.ecr.aws/lambda/python:3.9

# 必要なパッケージをインストール
RUN yum install -y gcc python3-devel

# 共通レイヤーの依存関係をインストール
COPY src/layers/common/python/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# AWS SDKでLocalStackを使用するための設定
ENV AWS_ENDPOINT_URL=""

# Lambda Runtime Interface Emulator (RIE) を使用
# RIEはベースイメージに含まれているため追加インストール不要

# ハンドラーのパスを設定するためのスクリプト
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'if [ -n "$LAMBDA_FUNCTION_DIR" ]; then' >> /entrypoint.sh && \
    echo '  export PYTHONPATH="$LAMBDA_FUNCTION_DIR:/opt/python:$PYTHONPATH"' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'if [ -n "$LAMBDA_HANDLER" ]; then' >> /entrypoint.sh && \
    echo '  exec /lambda-entrypoint.sh "$LAMBDA_HANDLER"' >> /entrypoint.sh && \
    echo 'else' >> /entrypoint.sh && \
    echo '  exec /lambda-entrypoint.sh "$@"' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 環境変数で指定されたハンドラーを実行
ENTRYPOINT ["/entrypoint.sh"]