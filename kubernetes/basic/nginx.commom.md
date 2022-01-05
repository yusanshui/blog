1. Chart.yaml
* dependencies
    + common

2. charts/common/templates/_capabilities.tpl(v1 v1/beta)
* common.capabilities.kubeVersion
    + global.kubervision > .Values.KubeVersion > .Capabilities.KubeVersion(built-in)
* common.capabilities.policy.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.networkPolicy.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.cronjob.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.deployment.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.statefulset.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.ingress.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.rbac.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.crd.apiVersion
    + include common.capabilities.kubeVersion
* common.capabilities.supportsHelmVersion
    + regexMatch
    + key HelmVersion in <3.3 results in a "interface not found" error.

3. charts/common/templates/_names
* common.names.name
* common.names.chart
* common.names.fullname
* common.names.dependency.fullname

4. charts/common/templates/_labels
* common.labels.standard
    + include common.names.name
    + include common.names.chart
    + .Release.Name
    + .Release.Service
* common.labels.matchLabels
    + include common.names.name
    + .Release.Name

5. charts/common/templates/_affinities.tpl
* common.affinities.nodes.soft
* common.affinities.nodes.hard
* common.affinities.nodes
    + include common.affinities.nodes.soft
    + include common.affinities.nodes.hard
* common.affinities.pods.soft
    + include common.labels.matchLabels
* common.affinities.pods.hard
    + include common.labels.matchLabels
* common.affinities.pods
    + include common.affinities.pods.soft
    + include common.affinities.pods.hard

6. charts/common/templates/_utils.tpl
* common.utils.fieldToEnvVar
* common.utils.secret.getvalue
    + include common.utils.fieldToEnvVar
* common.utils.getValueFromKey
* common.utils.getKeyFromList
    + include common.utils.getValueFromKey

7. charts/common/validations/_validations.tpl 
* common.validations.values.single.empty
    + include common.utils.getValueFromKey
    + include common.utils.fieldToEnvVar
    + include common.utils.secret.getvalue
* common.validations.values.multiple.empty
    + include common.validations.values.single.empty

8. charts/common/templates/_errors.tpl(through error when upgrading using empty passwords values that must not be empty.)
* common.errors.upgrade.passwords.empty
    + include common.validations.values.single.empty

9. charts/common/templates/_tplvalues.tpl
* common.tplvalues.render

10. charts/common/templates/_images.tpl
* common.images.image
* common.images.pullSecrets
* common.images.renderPullSecrets
    + include common.tplvalues.render

11. charts/common/templates/_ingress.tpl
* common.ingress.backend
    + include common.capabilities.ingress.apiVersion
* common.ingress.supportsPathType
    + include common.capabilities.kubeVersion
* common.ingress.supportsIngressClassname
    + include common.capabilities.kubeVersion

12. charts/common/templates/_secrets.tpl
* common.secrets.name
    + include common.names.fullname
* common.secrets.key
* common.secrets.passwords.manage
    + include common.utils.getKeyFromList
    + include common.utils.getValueFromKey
    + include common.validations.values.single.empty
    + include common.errors.upgrade.passwords.empty
* common.secrets.exists

13. charts/common/templates/_storage.tpl
* common.storage.class

14. charts/common/templates/_warngings.tpl
* common.warnings.rollingTag

15. charts/common/templates/validations/_cassandra.tpl
* common.cassandra.values.existingSecret
* common.cassandra.values.enabled
* common.cassandra.values.key.dbUser
* common.validations.values.cassandra.passwords
    + include common.validations.values.multiple.empty

16. charts/common/templates/validations/_mariadb.tpl
* common.mariadb.values.auth.existingSecret
* common.mariadb.values.enabled
* common.mariadb.values.architecture
* common.mariadb.values.key.auth
* common.validations.values.mariadb.passwords
    + include common.mariadb.values.auth.existingSecret
    + include common.mariadb.values.enabled
    + include common.mariadb.values.architecture
    + include common.mariadb.values.key.auth

17. charts/common/templates/validations/_mongodb.tpl
* common.mongodb.values.auth.existingSecret
* common.mongodb.values.enabled
* common.mongodb.values.key.auth
* common.mongodb.values.architecture
* common.validations.values.mongodb.passwords
    + include common.mongodb.values.auth.existingSecret
    + include common.mongodb.values.enabled
    + include common.mongodb.values.key.auth
    + include common.mongodb.values.architecture
    + include common.utils.getValueFromKey
    + include common.validations.values.multiple.empty

18. charts/common/templates/validations/_postgresql.tpl
* common.postgresql.values.use.global
* common.postgresql.values.existingSecret
    + include common.postgresql.values.use.global
* common.postgresql.values.enabled
* common.postgresql.values.key.postgressPassword
    + include common.postgresql.values.use.global
* common.postgresql.values.enabled.replication
* common.postgresql.values.key.replicationPassword
* common.validations.values.postgresql.passwords
    + include common.postgresql.values.existingSecret
    + include common.postgresql.values.enabled
    + include common.postgresql.values.key.postgressPassword
    + include common.postgresql.values.key.replicationPassword
    + include common.postgresql.values.enabled.replication
    + include common.validations.values.multiple.empty

19. charts/common/templates/validations/_redis.tpl
* common.redis.values.enabled
* common.redis.values.key.prefix
* common.redis.values.standarized.version
* common.validations.values.redis.passwords
    + include common.redis.values.enabled
    + include common.redis.values.keys.prefix
    + include common.redis.values.standarized.version

2. templates/_help.tpl(依赖common)
* common.capabilities.networkPolicy.apiVersion
