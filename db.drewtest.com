$TTL 86400
@   IN  SOA ns1.drewtest.com. admin.drewtest.com. (
            2024100601  ; Serial
            3600        ; Refresh
            1800        ; Retry
            604800      ; Expire
            86400       ; Minimum TTL
            )
@   IN  NS  ns1.drewtest.com.
ns1 IN  A   127.0.0.1
@   IN  A   127.0.0.1
www IN  A   127.0.0.1

@   IN DNSKEY 257 3 8 AwEAAdGuRjst0/cSswCychPozqKl648Ra9FUq2/39U73o4HLUaTq+GGM 3atZoV83k2T+z+SfOYUcs8bOQbROUy+xU7oc3AhxUrZt/5hKoaSwRKmf o3GSeL80jf59/xKyNjknCqAjcKigXtGrllHQFGqtE5LwdQrf8ZwKFEjG sYtld84vPnKfaSRSwtHT/pquraYJOdjR53lLtSqvIzBWTQKgD8dEYImH XSSpCVtUL0sMIbAvL9nh/g1cNBz8UaZoVmr8imUAdLpBH47WFm2bEJCq XI2EHk95ldQNigkhn4Djdth9nHnr58Psti0sNFhEIULDihZaw7Z81pvV YyXEBNpaygU=
@   IN DNSKEY 256 3 8 AwEAAbuWTFnzH7MBx7Eo/n2Yqr0cHB7inrXwuZOAtFOMHiti5cjZ62gr nEoTEhRRpj6OR032lkuU/5VZgLP9XdMwlXfvJd7mv+ekSrfQzeuigMVI t1/R+qEr0h+AIVp6qiPme3rFx/wxT/cLynz/N5qQaf4W1bRP0be2rfdY 66G/ogokgHO/eqRsglPArrnq3LXABekMyAJ58dKlLPwuXanQ85301uhj n7ocwU9uE9CgGQo5u0KfhCid5wLMHeHfJXQKB6J/tc3vs1awxnF+rFGE eRdd5DEH3v7frFWDR5Mftzac0y5Mz0VFWfFteGSUkzM2CCAd/pd2MQdl 2fsfxTG8P0s=
