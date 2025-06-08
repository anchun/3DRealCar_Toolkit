# source ~/.bashrc
dataset_dir=$1
first_index=$2
last_index=$3
if [ -z ${dataset_dir} ]; then
    echo "Must give dataset_dir"
    exit 0;
fi
if [ -z ${first_index} ]; then
    first_index=0
fi
if [ -z ${last_index} ]; then
    last_index=0
fi
cd "$(dirname "$0")/data_preprocess"
mkdir -p ${dataset_dir}/processed
touch ${dataset_dir}/processed/.processed
mkdir -p ${dataset_dir}/invalid_dataset
touch ${dataset_dir}/invalid_dataset/.processed
mkdir -p ${dataset_dir}/invalid_pcddata
touch ${dataset_dir}/invalid_pcddata/.processed
dirs=$(find "$dataset_dir" -maxdepth 1 -mindepth 1 -type d | sort)
total=$(echo "$dirs" | wc -l)
if [ "$last_index" -eq 0 ]; then
    last_index=$total
fi
echo "Processing ${dataset_name} with total count $total, and index range: $first_index to $last_index"
count=0
for dir in $dirs; do
    count=$((count + 1))
    if [ "$count" -le "$first_index" ]; then
        continue
    fi
    if [ "$count" -gt "$last_index" ]; then
        continue
    fi
    dataset_name=$(basename "$dir")
    if [ -f ${dataset_dir}/${dataset_name}/.processed ]; then
        echo "Skip ${dataset_name} folder since it has been already processed!"
        continue
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]Processing dataset: $dataset_name"
    echo "./bash/pipeline.sh $dataset_name dataset"
    ./bash/pipeline.sh $dataset_name dataset $dataset_dir
    if [ ! -f ${dataset_dir}/${dataset_name}/colmap_processed/.dataset ]; then
        mv ${dataset_dir}/${dataset_name} ${dataset_dir}/invalid_dataset
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]dataset process failed! move this dataset to '${dataset_dir}/invalid_dataset' folder"
        continue;
    fi
    echo "./bash/pipeline.sh $dataset_name segmentation"
    ./bash/pipeline.sh $dataset_name segmentation $dataset_dir
    echo "./bash/pipeline.sh $dataset_name pcd_clean"
    ./bash/pipeline.sh $dataset_name pcd_clean $dataset_dir
    echo "./bash/pipeline.sh $dataset_name pcd_standard"
    ./bash/pipeline.sh $dataset_name pcd_standard $dataset_dir
    echo "./bash/pipeline.sh $dataset_name pcd_rescale"
    ./bash/pipeline.sh $dataset_name pcd_rescale $dataset_dir
    if [ ! -f ${dataset_dir}/${dataset_name}/colmap_processed/.processed ]; then
        mv ${dataset_dir}/${dataset_name} ${dataset_dir}/invalid_pcddata
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]dataset process failed! move this dataset to '${dataset_dir}/invalid_pcddata' folder"
        continue;
    fi
    echo "./bash/pipeline.sh $dataset_name processed"
    ./bash/pipeline.sh $dataset_name processed $dataset_dir
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]Processing done: $dataset_name"
done

