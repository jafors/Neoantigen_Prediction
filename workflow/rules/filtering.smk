# rule filter_by_annotation:
#     input:
#         get_annotated_bcf
#     output:
#         "results/calls/{group}.{filter}.filtered.bcf"
#     params:
#         filter=lambda w: config["calling"]["filter"][w.filter]
#     conda:
#         "../envs/snpsift.yaml"
#     shell:
#         "bcftools view {input} | SnpSift filter \"{params.filter}\" | bcftools view -Ob > {output}"


rule control_fdr:
    input:
        get_annotated_bcf
    output:
        "results/calls/{pair}.{vartype}.{event}.fdr-controlled.bcf"
    params:
        threshold=config["calling"]["fdr-control"]["threshold"],
        events=lambda wc: config["calling"]["fdr-control"]["events"][wc.event]["varlociraptor"]
    conda:
        "../envs/varlociraptor.yaml"
    shell:
        "varlociraptor filter-calls control-fdr {input} --var {wildcards.vartype} "
        "--events {params.events} --fdr {params.threshold} > {output}"


def get_merge_input(ext=".bcf"):
    def inner(wildcards):
        return expand("results/calls/{{pair}}.{vartype}.{{event}}.fdr-controlled{ext}",
                      ext=ext,
                      vartype=["SNV", "INS", "DEL", "MNV"],
                      filter=config["calling"]["fdr-control"]["events"][wildcards.event])
    return inner


rule merge_calls:
    input:
        calls=get_merge_input(".bcf"),
        idx=get_merge_input(".bcf.csi")
    output:
        "results/merged-calls/{pair}.{event}.fdr-controlled.bcf"
    params:
        "-a -Ob"
    wrapper:
        "0.37.1/bio/bcftools/concat"
