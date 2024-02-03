node {
    def app
    
    stage('Clone repository') { // for display purposes
        cleanWs()
        //git branch: 'main', changelog: false, poll: false, url: '...'
        checkout scm
    }
    stage('Build') {
        app = docker.build("dddmaster/docker-samba-webmin", "--network host .")
    }
    
    stage('push') {
        // This step should not normally be used in your script. Consult the inline help for details.
        withDockerRegistry(credentialsId: 'dockerhub') {
            app.push('latest')
        }
    }
}