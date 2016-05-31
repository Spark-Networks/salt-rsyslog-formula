{% from "rsyslog/map.jinja" import rsyslog with context %}

rsyslog:
  pkg.installed:
    - name: {{ rsyslog.package }}
  file.managed:
    - name: {{ rsyslog.config }}
    - template: jinja
    - source: salt://rsyslog/templates/{{ salt['pillar.get']('rsyslog-template', 'rsyslog.conf.jinja') }}
    - context:
      config: {{ salt['pillar.get']('rsyslog', {}) }}
  service.running:
    - enable: True
    - name: {{ rsyslog.service }}
    - require:
      - pkg: {{ rsyslog.package }}
    - watch:
      - file: {{ rsyslog.config }}

workdirectory:
  file.directory:
    - name: {{ rsyslog.workdirectory }}
    - user: {{ rsyslog.runuser }}
    - group: {{ rsyslog.rungroup }}
    - mode: 755
    - makedirs: True

{% if grains['os_family'] == 'RedHat' %}
syslog:
  service.dead:
    - enable: False
    - require_in:
      - service: {{ rsyslog.service }}
{% endif %}


rsyslog.d:
  file.directory:
    - name: {{ rsyslog.custom_config_path }}
    - user: {{ rsyslog.runuser }}
    - group: {{ rsyslog.rungroup }}
    - mode: 755
    - makedirs: True
    - order: 1

{% for filename in salt['pillar.get']('rsyslog:custom', []) %}
{% set basename = filename.split('/')|last %}
rsyslog_custom_{{basename}}:
  file.managed:
    - name: {{ rsyslog.custom_config_path }}/{{ basename|replace(".jinja", ".conf") }}
    {% if basename != filename %}
    - source: {{ filename }}
    {% else %}
    - source: salt://rsyslog/templates/{{ filename }}
    {% endif %}
    {% if filename.endswith('.jinja') %}
    - template: jinja
    {% endif %}
    - context:
      config: {{ salt['pillar.get']('rsyslog', {})|json }}
    - watch_in:
      - service: {{ rsyslog.service }}
{% endfor %}
