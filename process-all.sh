# source ~/.bashrc
dataset_dir=$1
if [ -z ${dataset_dir} ]; then
    echo "Must give dataset_dir"
    exit 0;
fi
cd "$(dirname "$0")/data_preprocess"
mkdir -p ${dataset_dir}/invalid
touch ${dataset_dir}/invalid/.processed
dirs=$(find "$dataset_dir" -maxdepth 1 -mindepth 1 -type d | sort)
total=$(echo "$dirs" | wc -l)
count=0
for dir in $dirs; do
    count=$((count + 1))
    dataset_name=$(basename "$dir")
    if [ -f ${dataset_dir}/${dataset_name}/.processed ]; then
        echo "Skip ${dataset_name} folder since it has been already processed!"
        continue
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]Processing dataset: $dataset_name"
    echo "./bash/pipeline.sh $dataset_name dataset"
    ./bash/pipeline.sh $dataset_name dataset $dataset_dir
    if [ ! -f ${dataset_dir}/${dataset_name}/colmap_processed/.dataset ]; then
        mv ${dataset_dir}/${dataset_name} ${dataset_dir}/invalid
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]dataset process failed! move this dataset to '${dataset_dir}/invalid' folder"
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
    echo "./bash/pipeline.sh $dataset_name processed"
    ./bash/pipeline.sh $dataset_name processed $dataset_dir
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$count/$total]Processing done: $dataset_name"
done

