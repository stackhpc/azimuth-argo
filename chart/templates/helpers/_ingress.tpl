{{- define "azimuth-argo.ingress.baseDomain" -}}
{{- .Values.ingress.baseDomain | required "ingress.baseDomain is required" | quote }}
{{- end }}

{{- define "azimuth-argo.ingress.tls.annotations" -}}
{{- with .Values.certManager }}
{{- if and .enabled .acmeHttp01Issuer.enabled }}
cert-manager.io/cluster-issuer: {{ .acmeHttp01Issuer.name }}
{{- end }}
{{- end }}
{{- end }}
