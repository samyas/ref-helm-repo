{{/* Short name of the chart */}}
{{- define "crococoder-status.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Full resource name: <release>-<chart>, or just the release if it already contains the chart name */}}
{{- define "crococoder-status.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Labels used by the Service and the ServiceMonitor to find the Pods. Never change them after first deploy. */}}
{{- define "crococoder-status.selectorLabels" -}}
app.kubernetes.io/name: {{ include "crococoder-status.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Labels set on every resource */}}
{{- define "crococoder-status.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "crococoder-status.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Full image reference. Enforces the project rule: an exact tag, never "latest". */}}
{{- define "crococoder-status.image" -}}
{{- $tag := required "image.tag must be set to an exact version such as sha-1a2b3c4 (set it in the environment values file)" .Values.image.tag -}}
{{- if eq $tag "latest" -}}
{{- fail "image.tag must not be 'latest': pin an exact version" -}}
{{- end -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}
