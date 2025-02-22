package lib

import data.lib.bundles
import data.lib.refs

pipelinerun_att_build_types := [
	"tekton.dev/v1beta1/PipelineRun",
	# Legacy build type
	"https://tekton.dev/attestations/chains/pipelinerun@v2",
]

taskrun_att_build_types := [
	"tekton.dev/v1beta1/TaskRun",
	# Legacy build type
	"https://tekton.dev/attestations/chains@v2",
]

hacbs_test_task_result_name := "HACBS_TEST_OUTPUT"

java_sbom_component_count_result_name := "SBOM_JAVA_COMPONENTS_COUNT"

key_task_name := "__task_name"

key_bundle := "__bundle_name"

# These are the ones we're interested in
pipelinerun_attestations := [att |
	att := input.attestations[_]
	att.predicate.buildType == pipelinerun_att_build_types[_]
]

# These ones we don't care about any more
taskrun_attestations := [att |
	att := input.attestations[_]
	att.predicate.buildType == taskrun_att_build_types[_]
]

tasks_from_pipelinerun := [task |
	att := pipelinerun_attestations[_]
	task := att.predicate.buildConfig.tasks[_]
]

# All results from the attested PipelineRun with the provided name. Results are
# expected to contain a JSON value. The JSON value will be augmented with a key
# "__task_name" that will hold the name of the TaskRun where the named result
# was found.
results_named(name) = results {
	results := [r |
		task := tasks_from_pipelinerun[_]
		result := task.results[_]
		result.name == name
		result_map := json.unmarshal(result.value)

		# Inject the task data, currently task name and task bundle image
		# reference so we can show it in failure messages
		r := object.union(result_map, task_data(task))
	]
}

# Returns the data relating to the task if the task is referenced from a bundle
task_data(task) = info {
	r := refs.task_ref(task)
	info := {key_task_name: r.name, key_bundle: r.bundle}
}

# Returns the data relating to the task if the task is not referenced from a
# bundle
task_data(task) = info {
	not refs.task_ref(task)
	info := {key_task_name: task.name}
}

# (Don't call it test_results since test_ means a unit test)
results_from_tests = results {
	all_results := results_named(hacbs_test_task_result_name)

	results := [result |
		result := all_results[_]
		result[key_bundle]
		bundle := result[key_bundle]
		bundles.is_acceptable(bundle)
	]
}

# Check for a task by name. Return the task if found
task_in_pipelinerun(name) = task {
	task := tasks_from_pipelinerun[_]
	task.name == name
	task
}

# Check for a task result by name
result_in_task(task_name, result_name) {
	task := task_in_pipelinerun(task_name)
	task_result := task.results[_]
	task_result.name == result_name
}

# Check for a Succeeded status from a task
task_succeeded(name) {
	task := task_in_pipelinerun(name)
	task.status == "Succeeded"
}
