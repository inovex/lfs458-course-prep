FROM hashicorp/terraform:0.12.7

RUN apk add putty && apk add bash && apk add zip
