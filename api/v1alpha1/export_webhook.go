/*
Copyright 2021.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	ctrl "sigs.k8s.io/controller-runtime"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
)

// log is for logging in this package.
var exportlog = logf.Log.WithName("export-resource")

func (r *Export) SetupWebhookWithManager(mgr ctrl.Manager) error {
	return ctrl.NewWebhookManagedBy(mgr).
		For(r).
		Complete()
}

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!

//+kubebuilder:webhook:path=/mutate-primer-gitops-io-v1alpha1-export,mutating=true,failurePolicy=fail,sideEffects=None,groups=primer.gitops.io,resources=exports,verbs=create;update,versions=v1alpha1,name=mexport.kb.io,admissionReviewVersions={v1,v1beta1}

var _ webhook.Defaulter = &Export{}

// Default implements webhook.Defaulter so a webhook will be registered for the type
func (r *Export) Default() {
	exportlog.Info("default", "name", r.Name)

	// TODO(user): fill in your defaulting logic.
}
