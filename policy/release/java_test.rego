package policy.release.java

import data.lib
import data.lib.bundles

test_all_good {
	attestations := [lib.att_mock_helper_ref(lib.java_sbom_component_count_result_name, {"redhat": 12, "rebuilt": 42}, "java-task-1", bundles.acceptable_bundle_ref)]
	lib.assert_empty(deny) with data["task-bundles"] as bundles.bundle_data
		with input.attestations as attestations
}

test_has_foreign {
	attestations := [lib.att_mock_helper_ref(lib.java_sbom_component_count_result_name, {"redhat": 12, "rebuilt": 42, "central": 1}, "java-task-1", bundles.acceptable_bundle_ref)]
	lib.assert_equal(deny, {{"code": "java_foreign_dependencies", "effective_on": "2022-01-01T00:00:00Z", "msg": "Found Java dependencies from 'central', expecting to find only from 'rebuilt,redhat'"}}) with data["task-bundles"] as bundles.bundle_data
		with input.attestations as attestations
}

test_unacceptable_bundle {
	attestations := [lib.att_mock_helper_ref(lib.java_sbom_component_count_result_name, {"redhat": 12, "rebuilt": 42}, "java-task-1", "registry.img/unacceptable@sha256:digest")]
	lib.assert_empty(deny) with data["task-bundles"] as bundles.bundle_data
		with input.attestations as attestations
}
