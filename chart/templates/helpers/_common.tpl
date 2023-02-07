{{/*
Expand the name of the chart.
*/}}
{{- define "azimuth-argo.name" -}}
{{- default .Chart.Name .Values.nameOverride | lower | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified name for a chart-level resource.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "azimuth-argo.fullName" -}}
{{- if .Values.fullNameOverride }}
{{- .Values.fullNameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | lower | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | lower | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a fully qualified name for a component resource.
*/}}
{{- define "azimuth-argo.componentName" -}}
{{- $ctx := index . 0 }}
{{- $componentName := index . 1 }}
{{- $fullName := include "azimuth-argo.fullName" $ctx }}
{{- printf "%s-%s" $fullName $componentName | lower | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Selector labels for a chart-level resource.
*/}}
{{- define "azimuth-argo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "azimuth-argo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for a component resource.
*/}}
{{- define "azimuth-argo.componentSelectorLabels" -}}
{{- $ctx := index . 0 }}
{{- $componentName := index . 1 }}
{{- include "azimuth-argo.selectorLabels" $ctx }}
app.kubernetes.io/component: {{ $componentName }}
{{- end -}}

{{/*
Common labels for all resources.
*/}}
{{- define "azimuth-argo.commonLabels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | lower | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Labels for a chart-level resource.
*/}}
{{- define "azimuth-argo.labels" -}}
{{ include "azimuth-argo.commonLabels" . }}
{{ include "azimuth-argo.selectorLabels" . }}
{{- end }}

{{/*
Labels for a component resource.
*/}}
{{- define "azimuth-argo.componentLabels" -}}
{{ include "azimuth-argo.commonLabels" (index . 0) }}
{{ include "azimuth-argo.componentSelectorLabels" . }}
{{- end -}}

{{/*
Produces an Argo app destination.
*/}}
{{- define "azimuth-argo.app.destination" -}}
{{- $ctx := first . -}}
{{- $rest := rest . -}}
{{- if $ctx.Values.argocd.destination.name -}}
name: {{ $ctx.Values.argocd.destination.name }}
{{- else -}}
server: {{ $ctx.Values.argocd.destination.server }}
{{- end }}
{{- if $rest }}
namespace: {{ first $rest }}
{{- else }}
namespace: default
{{- end }}
{{- end }}

{{/*
Helper for merging values from a defaults template, a map and an overrides template.
*/}}
{{- define "azimuth-argo.util.merge" -}}
{{- $ctx := index . 0 -}}
{{- $defaultsTemplate := index . 1 | default "{}" -}}
{{- $map := index . 2 -}}
{{- $overridesTemplate := index . 3 | default "{}" -}}
{{- $defaults := tpl $defaultsTemplate $ctx | fromYaml -}}
{{- $overrides := tpl $overridesTemplate $ctx | fromYaml -}}
{{- mustMergeOverwrite $defaults $map $overrides | toYaml }}
{{- end }}

{{/*
Produces the values for a Helm installation.
*/}}
{{- define "azimuth-argo.util.helmValues" -}}
{{- $ctx := index . 0 -}}
{{- $cfg := index . 1 -}}
{{- $defaultsTemplate := default "{}" $cfg.release.defaultsTemplate -}}
{{-
  include
    "azimuth-argo.util.merge"
    (list $ctx $defaultsTemplate $cfg.release.values $cfg.release.valuesTemplate)
}}
{{- end }}

{{/*
Produces an Argo app source for a Helm installation.
*/}}
{{- define "azimuth-argo.app.source.helm" -}}
{{- $cfg := index . 1 -}}
repoURL: {{ $cfg.chart.repo }}
chart: {{ $cfg.chart.name }}
targetRevision: {{ $cfg.chart.version }}
helm:
  releaseName: {{ $cfg.release.name }}
  {{- with (include "azimuth-argo.util.helmValues" . | fromYaml) }}
  values: |
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

{{/*
Produces an Argo app source for a Kustomize installation.
*/}}
{{- define "azimuth-argo.app.source.kustomize" -}}
{{- $ctx := index . 0 -}}
{{- $cfg := index . 1 -}}
{{- $defaultsTemplate := default "{}" $cfg.defaultsTemplate -}}
{{-
  $kustomize :=
    include
      "azimuth-argo.util.merge"
      (list $ctx $defaultsTemplate $cfg.kustomize $cfg.kustomizeTemplate) |
    fromYaml
-}}
repoURL: {{ default $ctx.Values.kustomizeGitRepoURL $cfg.repo }}
path: {{ $cfg.path }}
targetRevision: {{ $cfg.version }}
{{- with $kustomize }}
kustomize: {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Produces an Argo app source for a list of manifests.

This uses the raw Helm chart to install a list of resources produced by a template.
*/}}
{{- define "azimuth-argo.app.source.manifests" -}}
{{- $ctx := index . 0 -}}
{{- $releaseName := index . 1 -}}
{{- $manifestsTemplate := index . 2 -}}
repoURL: {{ $ctx.Values.rawChart.repo }}
chart: {{ $ctx.Values.rawChart.name }}
targetRevision: {{ $ctx.Values.rawChart.version }}
helm:
  releaseName: {{ $releaseName }}
  values: |
    resources: {{ include $manifestsTemplate $ctx | nindent 6 }}
{{- end }}
