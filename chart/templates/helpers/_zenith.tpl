{{- define "azimuth-argo.zenith.fullName" -}}
{{- if contains "zenith-server" .Values.zenith.release.name }}
{{- .Values.zenith.release.name | lower | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-zenith-server" .Values.zenith.release.name | lower | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "azimuth-argo.zenith.componentName" -}}
{{- $context := index . 0 }}
{{- $componentName := index . 1 }}
{{- $fullName := include "azimuth-argo.zenith.fullName" $context }}
{{- printf "%s-%s" $fullName $componentName | lower | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "azimuth-argo.zenith.registrar.externalUrl" -}}
{{-
  printf "%s://%s.%s"
    (ternary "https" "http" .Values.ingress.tls.enabled)
    .Values.ingress.subdomains.zenithRegistrar
    .Values.ingress.baseDomain
}}
{{- end }}

{{- define "azimuth-argo.zenith.registrar.adminUrl" -}}
{{-
  printf "http://%s.%s"
    (include "azimuth-argo.zenith.componentName" (list . "registrar"))
    .Values.zenith.release.namespace
}}
{{- end }}

{{- define "azimuth-argo.zenith.sshd.host" -}}
{{- $values := include "azimuth-argo.util.helmValues" (list . .Values.zenith) | fromYaml -}}
{{- $serviceType := default "LoadBalancer" $values.sshd.service.type -}}
{{- if eq $serviceType "LoadBalancer" }}
  {{- if eq .Values.installMode "singlenode" }}
    {{- default (printf "sshd.%s" .Values.ingress.baseDomain) $values.sshd.service.loadBalancerIP }}
  {{- else }}
    {{- default "" $values.sshd.service.loadBalancerIP }}
  {{- end }}
{{- else if eq $serviceType "NodePort" }}
  {{- printf "sshd.%s" .Values.ingress.baseDomain }}
{{- end }}
{{- end }}

{{- define "azimuth-argo.zenith.sshd.port" -}}
{{- $values := include "azimuth-argo.util.helmValues" (list . .Values.zenith) | fromYaml -}}
{{- $serviceType := default "LoadBalancer" $values.sshd.service.type -}}
{{- if eq $serviceType "LoadBalancer" }}
{{- default 22 $values.sshd.service.port }}
{{- else if eq $serviceType "NodePort" }}
{{- default "" $values.sshd.service.nodePort }}
{{- end }}
{{- end }}
