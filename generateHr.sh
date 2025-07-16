#!/bin/bash
# TODO: put path for predefined repos here
fluxSystem="${LAB_PATH}"   # absolute path to flux-system cluster
export OUTPUT_DIR="rendered_files"        # where want to put generated files

file=''
print_usage() {
    echo instructions found here
}
while getopts 'f:p:n:h' flag; do
  case "${flag}" in
    f) file="${OPTARG}" ;;  # what file want to check
    p) GIT_PATH="${OPTARG}" ;;  # if using local gitrepo can put path to where gitRepo is located
    n) name="${OPTARG}" ;;  # TODO optional rended only if name of helm releases matches this, need if have multiple hr inside a file
    *) print_usage
       exit 1 ;;
  esac
done

echo "File:               ${file}"
echo "Path:               ${GIT_PATH}"
echo "Name:               ${name}"

# render gitrepo assuming that gitrepo is already cloned on host
renderGitRepoLocal() {
  fullPath=${1}
  echo "Full path:                        ${fullPath}"
  helm template -f "${fullPath}/values.yaml" -f "${OUTPUT_DIR}/tempVals.yaml" "${fullPath}" > "${OUTPUT_DIR}/hrTemplated.yaml"    # rendering hel chart with helm release provided values
  helm template -f "${fullPath}/values.yaml"  "${fullPath}" > "${OUTPUT_DIR}/originalHelm.yaml"                                 # rendering helm chart with default values
  diff "${OUTPUT_DIR}/hrTemplated.yaml"  "${OUTPUT_DIR}/originalHelm.yaml" > "${OUTPUT_DIR}/diff.diff"                                                          # seeing what diffs between original and what is going to be rendered
  cat ${OUTPUT_DIR}/hrTemplated.yaml
}

renderHelmRepo() {
  sourceName=${1}
  chartPath=${2}
  sourceNameSpace=${3}
  helmRepoUrl=$(kubectl get helmrepo "${sourceName}" -n "${sourceNameSpace}" -o yaml | yq '.spec.url')
  echo "helmRepoUrl:   ${helmRepoUrl}"
  if [[ "${helmRepoUrl}" == "null"  ]]; then
    echo helm repo url cant be found, exiting
    exit 1
  fi

  helm repo add "${sourceName}" "${helmRepoUrl}"
  helm repo update "${sourceName}"
  echo "Templating:"
  helm template "${sourceName}/${chartPath}"
}

yq -s  ' "'${OUTPUT_DIR}'/doc_" + $index + ".yaml"' "${file}"  # outputs split files to temporary dir
for splitFile in "${OUTPUT_DIR}"/*; do
  kind=$(yq '.kind' "${splitFile}")
  echo "${kind}"
  if [[ "${kind}" == "HelmRelease" ]] ;then
    echo "found helmRelease" 
    chartPath=$(yq '.spec.chart.spec.chart' "${splitFile}")
    type=$(yq '.spec.chart.spec.sourceRef.kind' "${splitFile}")
    sourceName=$(yq '.spec.chart.spec.sourceRef.name' "${splitFile}")
    sourceNameSpace=$(yq '.spec.chart.spec.sourceRef.namespace' "${splitFile}")
    chartPath="${chartPath#./}"  # removing trailing characters so can do correct path in case it is gitRepo
    echo "chartPath:                         ${chartPath}"
    echo "type:                              ${type}"
    echo "name:                              ${sourceName}"
    echo "Source ns:                         ${sourceNameSpace}"
    echo Values found
    yq '.spec.values' "${file}"
    file=$(yq  '.spec.values' "${file}")
    echo "${file}" > "${OUTPUT_DIR}/tempVals.yaml"



    # logic to determine how to handle different sources
    if [[ "$type" == "GitRepository" ]]; then
      echo Found gitRepo
      renderGitRepoLocal "${GIT_PATH}/${chartPath}"
    elif [[ "$type" == "HelmRepository" ]]; then
      echo Found helmRepo
      renderHelmRepo "${sourceName}" "${chartPath}" "${sourceNameSpace}"
    else
      echo "no doing anything"
    fi

  else
    echo "not helmRelease"
  fi
  echo "========="

done











# rm tempVals.yaml
