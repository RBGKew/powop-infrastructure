{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 | trimSuffix "-" -}}
{{- end -}}

{{/* Include cloudsql proxy sidecar container */}}
{{- define "cloudsql_proxy" }}
          env:
            - name: JDBC_DRIVER_URL
              value: jdbc:mysql://127.0.0.1:3306/emonocot
        - name: cloudsql-proxy
          image: b.gcr.io/cloudsql-docker/gce-proxy:1.05
          command: ["/cloud_sql_proxy", "--dir=/cloudsql",
                    "-instances={{ .Values.db.cloudsql.connection }}=tcp:3306",
                    "-credential_file=/secrets/cloudsql/cloudsql-credentials.json"]
          volumeMounts:
            - name: cloudsql-oauth-credentials
              mountPath: /secrets/cloudsql
              readOnly: true
            - name: ssl-certs
              mountPath: /etc/ssl/certs
      volumes:
        - name: cloudsql-oauth-credentials
          secret:
            secretName: cloudsql-oauth-credentials
        - name: ssl-certs
          hostPath:
            path: /etc/ssl/certs
{{- end -}}
