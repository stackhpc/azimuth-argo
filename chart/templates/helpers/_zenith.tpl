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

{{- define "azimuth-argo.zenith.registrar.adminUrl" -}}
{{-
  printf "http://%s.%s"
    (include "azimuth-argo.zenith.componentName" (list . "registrar"))
    .Values.zenith.release.namespace
}}
{{- end }}
