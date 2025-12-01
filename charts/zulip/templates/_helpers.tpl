{{/*
Expand the name of the chart.
*/}}
{{- define "zulip.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "zulip.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "zulip.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "zulip.labels" -}}
helm.sh/chart: {{ include "zulip.chart" . }}
{{ include "zulip.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "zulip.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zulip.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PostgreSQL labels
*/}}
{{- define "zulip.postgresql.labels" -}}
helm.sh/chart: {{ include "zulip.chart" . }}
app.kubernetes.io/name: {{ include "zulip.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgresql
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "zulip.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zulip.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgresql
{{- end }}

{{/*
Memcached labels
*/}}
{{- define "zulip.memcached.labels" -}}
helm.sh/chart: {{ include "zulip.chart" . }}
app.kubernetes.io/name: {{ include "zulip.name" . }}-memcached
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: memcached
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "zulip.memcached.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zulip.name" . }}-memcached
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: memcached
{{- end }}

{{/*
Redis labels
*/}}
{{- define "zulip.redis.labels" -}}
helm.sh/chart: {{ include "zulip.chart" . }}
app.kubernetes.io/name: {{ include "zulip.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: redis
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "zulip.redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zulip.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: redis
{{- end }}

{{/*
RabbitMQ labels
*/}}
{{- define "zulip.rabbitmq.labels" -}}
helm.sh/chart: {{ include "zulip.chart" . }}
app.kubernetes.io/name: {{ include "zulip.name" . }}-rabbitmq
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: rabbitmq
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "zulip.rabbitmq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zulip.name" . }}-rabbitmq
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: rabbitmq
{{- end }}

