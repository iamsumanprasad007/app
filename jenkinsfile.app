node {
    def app

    stage('Clone repository') {
    /* Let's make sure we have the repository cloned to our workspace & update as repo*/
        checkout scm
    }

    stage('Build image') {
        /* This builds the actual image; synonymous to
         * docker build on the command line */

        app = docker.build("iamsumanprasad007/app") //dockerhub username/repo
    }

    stage('Push image') {
        /* Finally, we'll push the image into Docker Hub */
        // here providng dockerhub url and it's credentials that we have provided in jenkins
        docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
            app.push("latest")
        }
    }
}
