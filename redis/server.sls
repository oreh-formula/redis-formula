include:
  - redis.common


{% from "redis/map.jinja" import redis with context %}


{% set install_from   = redis.install_from|default('package') -%}
{% set svc_state      = redis.svc_state|default('running') -%}
{% set svc_onboot     = redis.svc_onboot|default(True) -%}
{% set cfg_version    = redis.cfg_version|default('2.8') -%}


{% if install_from == 'source' %}


{% set user           = redis.user|default('redis') -%}
{% set cfg_name       = redis.cfg_name|default('/etc/redis/redis.conf') -%}
{% set group          = redis.group|default(user) -%}
{% set home           = redis.home|default('/var/lib/redis') -%}
{% set bin            = redis.bin|default('/usr/local/bin/redis-server') -%}

redis_group:
  group.present:
    - name: {{ group }}


redis_user:
  user.present:
    - name: {{ user }}
    - gid_from_name: True
    - home: {{ home }}
    - group: {{ group }}
    - require:
      - group: redis_group


redis-init-script:
  file.managed:
    - name: /etc/init.d/redis-server
    - template: jinja
    - source: salt://redis/templates/redis-server.jinja
    - mode: 0750
    - user: root
    - group: root
    - context:
        conf: {{ cfg_name }}
        user: {{ user }}
        bin: {{ bin }}
    - require:
      - sls: redis.common


redis-pid-dir:
  file.directory:
    - name: /var/db/redis
    - mode: 755
    - user: {{ user }}
    - group: {{ group }}
    - makedirs: True
    - require:
      - user: redis_user
    - recurse:
      - user
      - group


redis-log-dir:
  file.directory:
    - name: /var/log/redis
    - mode: 755
    - user: {{ user }}
    - group: {{ group }}
    - makedirs: True
    - require:
      - user: redis_user

redis-conf-dir:
  file.directory:
    - name: /etc/redis
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

redis-server:
  file:
    - name: /etc/redis/redis.conf
    - managed
    - template: jinja
    - source: salt://redis/templates/redis-{{ redis.cfg_version }}.conf.jinja
    - require:
      - file: redis-init-script
      - file: redis-pid-dir
      - file: redis-conf-dir
  service:
    - running
    - watch:
      - file: redis-init-script
      - file: redis-server


{% else %}


redis_config:
  file:
    - name: {{ redis.cfg_name }}
    - managed
    - template: jinja
    - source: salt://redis/templates/redis-{{ redis.cfg_version }}.conf.jinja
    - require:
      - pkg: {{ redis.pkg_name }}


redis_service:
  service:
    - name: {{ redis.svc_name }}
    - {{ svc_state }}
    - enable: {{ svc_onboot }}
    - watch:
      - file: {{ redis.cfg_name }}
    - require:
      - pkg: {{ redis.pkg_name }}


{% endif %}
