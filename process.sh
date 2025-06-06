# source ~/.bashrc
dataset_name=$1
dataset_dir=$2
if [ -z ${dataset_name} ]; then
    echo "Must give dataset_name"
    exit 0;
fi
if [ -z ${dataset_dir} ]; then
    dataset_dir=~/data/3drealcar
    echo "Need better to give dataset_dir, currently set to ${dataset_dir}"
fi
if [ -f ${dataset_dir}/${dataset_name}/.processed ]; then
    echo "Skip ${dataset_name} since it has been already processed!"
    exit 0;
fi

cd "$(dirname "$0")/data_preprocess"
./bash/pipeline.sh $dataset_name dataset $dataset_dir
./bash/pipeline.sh $dataset_name segmentation $dataset_dir
./bash/pipeline.sh $dataset_name pcd_clean $dataset_dir
./bash/pipeline.sh $dataset_name pcd_standard $dataset_dir
./bash/pipeline.sh $dataset_name pcd_rescale $dataset_dir
./bash/pipeline.sh $dataset_name processed $dataset_dir
