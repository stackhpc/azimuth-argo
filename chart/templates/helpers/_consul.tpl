{{- define "azimuth-argo.consul.host" -}}
{{-
  $values :=
    include
      "azimuth-argo.util.helmValues"
      (list . "azimuth-argo.consul.defaults" .Values.consul) |
    fromYaml
-}}
{{- $defaultPrefix := printf "%s-consul" .Values.consul.release.name -}}
{{- $prefix := dig "fullnameOverride" "" $values | default $defaultPrefix -}}
{{- printf "%s-server.%s" $prefix .Values.consul.release.namespace -}}
{{- end }}
