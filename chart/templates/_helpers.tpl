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
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
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
Produces an Argo app for the given inputs.
*/}}
{{- define "azimuth-argo.application" -}}
{{- $ctx := index . 0 }}
{{- $component := index . 1 }}
{{- $targetNamespace := index . 2 }}
{{- $sourceTemplate := index . 3 }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ include "azimuth-argo.componentName" (list $ctx $component) }}
  labels: {{ include "azimuth-argo.componentLabels" (list $ctx $component) | nindent 4 }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    {{- if $ctx.Values.argocd.destination.name }}
    name: {{ $ctx.Values.argocd.destination.name }}
    {{- else }}
    server: {{ $ctx.Values.argocd.destination.server }}
    {{- end }}
    {{- if $targetNamespace }}
    namespace: {{ $targetNamespace }}
    {{- end }}
  project: {{ include "azimuth-argo.fullName" $ctx }}
  source: {{ include $sourceTemplate $ctx | nindent 4 }}
  syncPolicy: {{ toYaml $ctx.Values.argocd.syncPolicy | nindent 4 }}
{{- end }}
