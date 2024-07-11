FROM locustio/locust

COPY locustfile.py /mnt/locust/

ENTRYPOINT [ "locust", "-f", "/mnt/locust/locustfile.py" ]