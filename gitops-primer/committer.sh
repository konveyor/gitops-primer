#!/bin/bash

# Setup SSH
mkdir -p ~/.ssh/controlmasters
chmod 711 ~/.ssh
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

cat - <<SSHCONFIG > ~/.ssh/config
Host *
  # Wait max 30s to establish connection
  ConnectTimeout 30
  # Control persist to speed 2nd ssh connection
  ControlMaster auto
  ControlPath ~/.ssh/controlmasters/%C
  ControlPersist 5
  # Disables warning when IP is added to known_hosts
  CheckHostIP no
  # Use the identity provided via attached Secret
  IdentityFile /keys/id_rsa
  # Enable protocol-level keepalive to detect connection failure
  ServerAliveCountMax 4
  ServerAliveInterval 30
  # Using protocol-level, so we don't need TCP-level
  TCPKeepAlive no
SSHCONFIG

# Setup the repository
[ "$(ls -A /repo)" ] || git clone $REPO /repo -q
cd /repo
git fetch -q 
git checkout $BRANCH -q
git config --global user.email "rcook@redhat.com"

# Identify all objects
EXCLUSIONS="events|machineautoscalers.autoscaling.openshift.io|credentialsrequests.cloudcredential.openshift.io|podnetworkconnectivitychecks.controlplane.operator.openshift.io|leases.coordination.k8s.io|machinehealthchecks.machine.openshift.io|machines.machine.openshift.io|machinesets.machine.openshift.io|baremetalhosts.metal3.io|pods.metrics.k8s.io|alertmanagerconfigs.monitoring.coreos.com|alertmanagers.monitoring.coreos.com|podmonitors.monitoring.coreos.com|volumesnapshots.snapshot.storage.k8s.io|profiles.tuned.openshift.io|tuneds.tuned.openshift.io|endpointslice.discovery.k8s.io|ippools.whereabouts.cni.cncf.io|overlappingrangeipreservations.whereabouts.cni.cncf.io|packagemanifests.packages.operators.coreos.com|endpointslice.discovery.k8s.io|endpoints"

IGNORES="primer|secret-key|kube-root-ca.crt|image-puller|kubernetes.io/service-account-token|builder|default|default-token|default-dockercfg|deployer"

RESOURCES=`kubectl api-resources --verbs=list --namespaced -o name | egrep -v $EXCLUSIONS | awk -F. '{print $1}'`

# Generate yamls
for o in $RESOURCES; do 
  if [[ ! -d /repo/$o ]]; then 
       mkdir /repo/$o &> /dev/null
  fi
  for i in `kubectl get $o --ignore-not-found | egrep -v ${IGNORES} | grep -v NAME | awk '{print $1}'`; do
      kubectl get -o=json $o $i | jq --sort-keys 'del(
            .metadata.annotations."control-plane.alpha.kubernetes.io/leader",
            .metadata.annotations."deployment.kubernetes.io/revision",
            .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
            .metadata.annotations."kubernetes.io/service-account.uid",
            .metadata.annotations."pv.kubernetes.io/bind-completed",
            .metadata.annotations."pv.kubernetes.io/bound-by-controller",
            .metadata.finalizers,
            .metadata.managedFields,
            .metadata.creationTimestamp,
            .metadata.generation,
            .metadata.resourceVersion,
            .metadata.selfLink,
            .metadata.uid,
            .spec.clusterIP,
            .spec.nodeName,
            .spec.progressDeadlineSeconds,
            .spec.revisionHistoryLimit,
            .spec.template.metadata.annotations."kubectl.kubernetes.io/restartedAt",
            .spec.template.metadata.creationTimestamp,
            .spec.volumeName,
            .spec.volumeMode,
            .status
        )' | python3 -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' > /repo/$o/$i.yaml ;
  done
done


case "${ACTION}" in
merge)
      git add *
      git commit -am 'bot commit'
      git push origin $BRANCH -q
      ;;
alert)
      git status -s
    ;;
*)
    error 1 "unknown action: ${ACTION}"
    ;;
esac

