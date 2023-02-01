
function gcp-reload-ssh-config --description "Reload SSH config to include new GCP VMs"
    gcloud compute config-ssh --remove
    gcloud compute config-ssh
end

