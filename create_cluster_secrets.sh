#!/bin/bash

ClusterName=${1}
BMHUser=${2:-Administrator}
BMHPw=${3:-changeme}

EncodedBMHUser=$(echo -n $BMHUser | base64 -w0)
EncodedBMHPw=$(echo -n $BMHPw | base64 -w0)

if [ -z $ClusterName ] ; then
	echo "ERROR: Must specify cluster name"
	echo "Example: \"./create_cluster_secrets.sh test-sno\""
	exit 1
fi

cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: ${ClusterName}
  labels:
    name: ${ClusterName}
EOF

cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: bmh-secret
  namespace: ${ClusterName}
data:
  username: ${EncodedBMHUser}
  password: ${EncodedBMHPw}
type: Opaque
EOF

pull_secret=$(oc get secret pull-secret -n openshift-config -o jsonpath='{.data.\.dockerconfigjson}')

cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: pull-secret
  namespace: ${ClusterName}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${pull_secret}
EOF
