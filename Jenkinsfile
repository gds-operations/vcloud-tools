#!/usr/bin/env groovy

repoName = JOB_NAME.split('/')[0]

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  try {
    stage("Checkout") {
      govuk.checkoutFromGitHubWithSSH(repoName)
    }

    stage("Clean up workspace") {
      govuk.cleanupGit()
    }

    stage("bundle install") {
      sh('source ./rbenv_version.sh')
      govuk.bundleApp()
    }

    stage("Run tests") {
      govuk.runTests()
    }

    if (env.BRANCH_NAME == "master") {
      stage("Publish gem") {
        sh('bundle exec rake publish_gem')
      }
    }
  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}

