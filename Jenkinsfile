def kubicLib = library("kubic-jenkins-library@${env.BRANCH_NAME}").com.suse.kubic

// Configure the build properties
properties([
    buildDiscarder(logRotator(numToKeepStr: '31', daysToKeepStr: '31')),
    disableConcurrentBuilds(),
    pipelineTriggers([cron('H H(3-5) * * *')])
])

def kvmTypeOptions = kubicLib.CaaspKvmTypeOptions.new();
kvmTypeOptions.vanilla = true
kvmTypeOptions.disableMeltdownSpectreFixes = false

coreKubicProjectPeriodic(
    environmentTypeOptions: kvmTypeOptions,
    workerCount: 1
) {
    // empty preBootstrapBody
} {
    stage('Add Node') {
        // create another worker node
        environment = updateEnvironmentCaaspKvm(
            environment: environment,
            typeOptions: environmentTypeOptions,
            masterCount: 3,
            workerCount: 2
        )

        // Register it via velum
        environment = addNode(
            environment: environment
        )
    }

    // Run the Core Project Tests again
    coreKubicProjectTests(
        environment: environment,
        podName: 'default'
    )

    return environment
}
