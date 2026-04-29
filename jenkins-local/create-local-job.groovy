import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

def jenkins = Jenkins.instance
def jobName = 'aceest-local-flow'
def job = jenkins.getItem(jobName)

if (job == null) {
  job = jenkins.createProject(WorkflowJob, jobName)
}

def pipelineScript = new File('/workspace/aceest-app/Jenkinsfile.local').text
job.definition = new CpsFlowDefinition(pipelineScript, true)
job.save()

println "Created/updated ${jobName}"
