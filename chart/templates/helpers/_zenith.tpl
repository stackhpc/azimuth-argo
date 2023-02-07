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
{{- if .Values.ingress.baseDomain }}
{{-
  printf "%s://%s.%s"
    (ternary "https" "http" .Values.ingress.tls.enabled)
    .Values.ingress.subdomains.zenithRegistrar
    .Values.ingress.baseDomain
}}
{{- end }}
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
{{- $serviceType := dig "sshd" "service" "type" "" $values | default "LoadBalancer" -}}
{{-
  $singleNodeDefault :=
    not (not .Values.ingress.baseDomain) |
      ternary (printf "sshd.%s" .Values.ingress.baseDomain) ""
-}}
{{- if eq $serviceType "LoadBalancer" }}
  {{- $loadBalancerIP := dig "sshd" "service" "loadBalancerIP" "" $values -}}
  {{- if eq .Values.installMode "singlenode" }}
    {{- default $singleNodeDefault $loadBalancerIP }}
  {{- else }}
    {{- $loadBalancerIP }}
  {{- end }}
{{- else if eq $serviceType "NodePort" }}
  {{- $singleNodeDefault }}
{{- end }}
{{- end }}

{{- define "azimuth-argo.zenith.sshd.port" -}}
{{- $values := include "azimuth-argo.util.helmValues" (list . .Values.zenith) | fromYaml -}}
{{- $serviceType := dig "sshd" "service" "type" "" $values | default "LoadBalancer" -}}
{{- if eq $serviceType "LoadBalancer" }}
  {{- dig "sshd" "service" "port" "" $values | default 22 }}
{{- else if eq $serviceType "NodePort" }}
  {{- dig "sshd" "service" "nodePort" "" $values }}
{{- end }}
{{- end }}
