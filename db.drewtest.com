$TTL 86400
@   IN  SOA ns1.drew-test. admin.drew-test. (
            2024100601  ; Serial
            3600        ; Refresh
            1800        ; Retry
            604800      ; Expire
            86400       ; Minimum TTL
            )
@   IN  NS  ns1.drew-test.
ns1 IN  A   127.0.0.1
@   IN  A   127.0.0.1
www IN  A   127.0.0.1
