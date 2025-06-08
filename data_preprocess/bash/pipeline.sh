# source ~/.bashrc
dataset_name=$1
command=$2
dataset_dir=$3

if [ -z ${dataset_name} ]; then
    echo "Must give dataset_name"
    exit 0;
fi
if [ -z ${command} ]; then
    echo "Must give command"
    exit 0;
fi
if [ -z ${dataset_dir} ]; then
    dataset_dir=~/data/3drealcar
    echo "Need better to give dataset_dir, currently set to ${dataset_dir}"
fi

# RDMA
cd "$(dirname "$(dirname "$0")")"
echo "current folder: $(pwd)"

# currently we only use colmap data
processed_type=colmap
processed_dataset_dir=${dataset_dir}/${dataset_name}/${processed_type}_processed
echo "processed_dataset_dir:" $processed_dataset_dir

# change to your own yaml
yaml_fn=resources/configs/demo.yaml

################################################################################
# Get processed type
################################################################################
pcd_clean_dir=pcd_clean
pcd_standard_dir=pcd_standard
pcd_rescale_dir=pcd_rescale
final_processed_dir=""
if [ -f ${processed_dataset_dir}/.dataset ]; then
    final_processed_dir=${processed_dataset_dir}
fi
if [ -f ${processed_dataset_dir}/${pcd_clean_dir}/.processed ]; then
    final_processed_dir=${pcd_clean_dir}
fi
if [ -f ${processed_dataset_dir}/${pcd_standard_dir}/.processed ]; then
    final_processed_dir=${pcd_standard_dir}
fi
if [ -f ${processed_dataset_dir}/${pcd_rescale_dir}/.processed ]; then
    final_processed_dir=${pcd_rescale_dir}
fi
echo "Last Processed type=${final_processed_dir}"

################################################################################
# Convert dataset from 3Dscanner to COLMAP
################################################################################
if [ $command == 'dataset' ]; then
    if [ -f ${processed_dataset_dir}/.dataset ]; then
        echo "Skip ${command} since has been already processed!"
        exit 0;
    fi
    if [ ! -d ${dataset_dir}/${dataset_name}/3dscanner_origin ]; then
        mkdir -p ${dataset_dir}/${dataset_name}/3dscanner_origin
        mv ${dataset_dir}/${dataset_name}/*.* ${dataset_dir}/${dataset_name}/3dscanner_origin
    fi
    python3 entrances/dataset_adaptor.py ${processed_type} \
        --search_dir ${dataset_dir}/${dataset_name}/3dscanner_origin \
        --save_dir ${processed_dataset_dir}
    mkdir -p ${processed_dataset_dir}/arkit
    cp -r ${dataset_dir}/${dataset_name}/3dscanner_origin/frame*.json ${processed_dataset_dir}/arkit/
    echo "copied arkit jsons"
    exit 0;
fi

################################################################################
# Extract semantic segmentation
################################################################################
# TODO: should fix bug when alpha channel is incorrect!
if [ $command == 'segmentation' ]; then
    if [ ! -f ${processed_dataset_dir}/.dataset ]; then
        echo "Call dataset first!"
        exit 0;
    fi
    if [ -f ${processed_dataset_dir}/.segmentation ]; then
        echo "Skip ${command} since has been already processed!"
        exit 0;
    fi
    while true
    do
        # Sometimes docker may not download SAM models from huggingface
        python3 utils/toolkit/extract_segmentation.py \
            --yaml ${yaml_fn} \
            --dataset_dir ${processed_dataset_dir}
        if [ -f ${processed_dataset_dir}/.segmentation ]; then
            exit 0;
        fi
    done
    exit 0;
fi

################################################################################
# PCD Cleaning
################################################################################
if [ $command == 'pcd_clean' ]; then
    if [ ! -f ${processed_dataset_dir}/.segmentation ]; then
        echo "Call segmentation first!"
        exit 0;
    fi
    if [ -f ${processed_dataset_dir}/${pcd_clean_dir}/.processed ]; then
        echo "Skip ${command} since has been already processed!"
        exit 0;
    fi
    python3 utils/toolkit/extract_foreground_pcd.py \
        --yaml ${yaml_fn} \
        --dataset_dir ${processed_dataset_dir} \
        --save_dir ${processed_dataset_dir}/${pcd_clean_dir}
    python3 utils/toolkit/visualize_dataset.py \
        --yaml ${yaml_fn} \
        --dataset_dir ${processed_dataset_dir}/${pcd_clean_dir} \
        --save_dir ${processed_dataset_dir}/${pcd_clean_dir}
    exit 0;
fi

################################################################################
# Standardize Coordinates
################################################################################
if [ $command == 'pcd_standard' ]; then
    if [ ! -f ${processed_dataset_dir}/${pcd_clean_dir}/.processed ]; then
        echo "Call pcd_clean first!"
        exit 0;
    fi
    if [ -f ${processed_dataset_dir}/${pcd_standard_dir}/.processed ]; then
        echo "Skip ${command} since has been already processed!"
        exit 0;
    fi
    python3 utils/toolkit/standarize_coordinates.py \
        --yaml ${yaml_fn} \
        --dataset_dir ${processed_dataset_dir}/${pcd_clean_dir} \
        --save_dir ${processed_dataset_dir}/${pcd_standard_dir} \
        --dataset_name ${dataset_name} \
        --manual_setting resources/pcd_standard.txt
    cp ${processed_dataset_dir}/${pcd_clean_dir}/trainval.meta ${processed_dataset_dir}/${pcd_standard_dir}/
    python3 utils/toolkit/visualize_dataset.py \
        --yaml ${yaml_fn} \
        --dataset_dir ${processed_dataset_dir}/${pcd_standard_dir} \
        --save_dir ${processed_dataset_dir}/${pcd_standard_dir}
    exit 0;
fi

################################################################################
# Rescale Coordinates
################################################################################
if [ $command == 'pcd_rescale' ]; then
    if [ ! -f ${processed_dataset_dir}/${pcd_standard_dir}/.processed ]; then
        echo "Call pcd_standard first!"
        exit 0;
    fi
    if [ -f ${processed_dataset_dir}/${pcd_rescale_dir}/.processed ]; then
        echo "Skip ${command} since has been already processed!"
        exit 0;
    fi
    python3 utils/toolkit/rescale_colmap.py \
        --yaml ${yaml_fn} \
        --dataset_dir ${processed_dataset_dir}/${pcd_standard_dir} \
        --save_dir ${processed_dataset_dir}/${pcd_rescale_dir}
    cp ${processed_dataset_dir}/${pcd_standard_dir}/trainval.meta ${processed_dataset_dir}/${pcd_rescale_dir}/
    python3 utils/toolkit/visualize_dataset.py \
        --yaml ${yaml_fn} \
        --dataset_dir ${processed_dataset_dir}/${pcd_rescale_dir} \
        --save_dir ${processed_dataset_dir}/${pcd_rescale_dir}
    touch ${processed_dataset_dir}/.processed
    exit 0;
fi

if [ $command == 'processed' ]; then
    if [ ! -f ${processed_dataset_dir}/${pcd_rescale_dir}/.processed ]; then
        echo "Call pcd_rescale first!"
        exit 0;
    fi
    processed_dir=${dataset_dir}/${dataset_name}/processed
    mkdir -p ${processed_dir}
    if [ -f ${dataset_dir}/${dataset_name}/.processed ]; then
        echo "Skip ${command} since has been already processed!"
        exit 0;
    fi
    echo "copying to ${processed_dir} ..."
    cp -aL ${processed_dataset_dir}/${pcd_rescale_dir}/images ${processed_dir}/
    cp -aL ${processed_dataset_dir}/${pcd_rescale_dir}/masks/sam ${processed_dir}/masks
    cp -aL ${processed_dataset_dir}/${pcd_rescale_dir}/sparse ${processed_dir}/
    echo "copy done to ${processed_dir}!"
    touch ${dataset_dir}/${dataset_name}/.processed
fi

if [ $command == 'clean' ]; then
    rm -rf ${processed_dataset_dir}
    echo "remove ${processed_dataset_dir} succeed!"
fi
