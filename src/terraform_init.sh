#!/bin/bash

function terraformInit {
  # Gather the output of `terraform init`.
  echo "init: info: initializing Terraform configuration in ${tfWorkingDir}"
  initOutput=$(echo '1' | TF_WORKSPACE=${tfWorkingDir} terraform init -input=false ${*} 2>&1)
  initExitCode=${?}

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${initExitCode} -eq 0 ]; then
    echo "init: info: successfully initialized Terraform configuration in ${tfWorkingDir}"
    echo "${initOutput}"
    echo
    exit ${initExitCode}
  fi

  # Exit code of !0 indicates failure.
  echo "init: error: failed to initialize Terraform configuration in ${tfWorkingDir}"
  echo "${initOutput}"
  echo

  # Comment on the pull request if necessary.
  if [ "${tfComment}" == "1" ] && [ -n "${tfCommentUrl}" ]; then
    initCommentWrapper="#### \`terraform init\` Failed

\`\`\`
${initOutput}
\`\`\`

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`, Workspace: \`${tfWorkspace}\`*"

    initCommentWrapper=$(stripColors "${initCommentWrapper}")
    echo "init: info: creating JSON"
    initPayload=$(echo "${initCommentWrapper}" | jq -R --slurp '{body: .}')
    echo "init: info: commenting on the pull request"
    echo "${initPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${tfCommentUrl}" > /dev/null
  fi

  exit ${initExitCode}
}
