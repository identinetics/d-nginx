pipeline {
    agent any
    options { disableConcurrentBuilds() }
    parameters {
        string(defaultValue: 'True', description: '"true"=initial cleanup: remove container and volumes; otherwise leave empty', name: 'start_clean')
        string(defaultValue: '', description: '"true"=Force "docker build --nocache"; otherwise leave empty', name: 'nocache')
        string(defaultValue: '', description: '"true"=push docker image after build; otherwise leave empty', name: 'pushimage')
        string(defaultValue: '', description: '"true"=keep running after test; otherwise leave empty to delete container and volumes', name: 'keep_running')
        string(description: '"true"=overwrite default docker registry user; otherwise leave empty', name: 'docker_registry_user')
        string(description: '"true"=overwrite default docker registry host; otherwise leave empty', name: 'docker_registry_host')
    }

    stages {
        stage('docker cleanup') {
            steps {
                sh '''
                    rm conf.sh 2> /dev/null || true
                    cp conf.sh.default conf.sh
                    ./dscripts/manage.sh rm 2>/dev/null || true
                    ./dscripts/manage.sh rmvol 2>/dev/null || true
                '''
            }
        }
        stage('Build') {
            steps {
                echo "==========================="
                sh 'set +x; source ./conf.sh; echo "Building $IMAGENAME"'
                echo "Pipeline args: nocache=$nocache; pushimage=$pushimage; docker_registry_user=$docker_registry_user; docker_registry_host=$docker_registry_host"
                echo "==========================="
                sh '''
                    set +x
                    echo [[ "$docker_registry_user" ]] && echo "DOCKER_REGISTRY_USER $docker_registry_user"  > local.conf
                    echo [[ "$docker_registry_host" ]] && echo "DOCKER_REGISTRY_HOST $docker_registry_host"  >> local.conf
                    source ./conf.sh
                    [[ "$pushimage" ]] && pushopt='-P'
                    [[ "$nocache" ]] && nocacheopt='-c'
                    ./dscripts/build.sh -p $nocacheopt $pushopt
                    echo "=== build completed with rc $?"
                '''
                sh '''
                    echo "generate run script"
                    ./dscripts/run.sh -w
                '''
            }
        }
    }
    post {
        always {
            echo 'container status'
            sh './dscripts/manage.sh status'
            echo 'Remove container, volumes'
            sh '''
                if [[ "$keep_running" ]]; then
                   echo "Keep container running"
                else
                    ./dscripts/manage.sh rm 2>/dev/null || true
                    ./dscripts/manage.sh rmvol 2>/dev/null || true
                fi
            '''
        }
    }
}