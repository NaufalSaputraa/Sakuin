# QLoRA Gemma 4 E2B on RTX 4060 8GB - Sakuin tuning
# pip install unsloth trl transformers datasets accelerate bitsandbytes
from unsloth import FastLanguageModel
import torch

# Load Gemma 4 E2B 4-bit (NF4) for 8GB VRAM
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = r"C:\Users\Naufal Saputra\Downloads\model.litertlm", # ganti ke path HF jika pakai HF
    max_seq_length = 2048,
    dtype = None,
    load_in_4bit = True, # 4-bit NF4 -> ~1.2GB + LoRA ~50MB = ~6.5GB total
)

# LoRA r=32 alpha=64 untuk 8GB
model = FastLanguageModel.get_peft_model(model, r=32, target_modules=["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"], lora_alpha=64, lora_dropout=0, bias="none", use_gradient_checkpointing="unsloth")

# Dataset dummy transaksi Indonesia 100 baris
# Format: instruction, input, output -> JSONL
# Contoh: {"instruction": "Tambahkan pengeluaran warung 20rb", "input": "", "output": "{\"amount\": 20000, \"category\": \"warung\", \"title\": \"Warung\"}"}

# Training: batch 2, grad accum 4, bf16, 1-2 jam di RTX 4060
# from trl import SFTTrainer
# trainer = SFTTrainer(model=model, tokenizer=tokenizer, train_dataset=dataset, dataset_text_field="text", max_seq_length=2048, args=TrainingArguments(per_device_train_batch_size=2, gradient_accumulation_steps=4, warmup_steps=5, max_steps=100, learning_rate=2e-4, fp16=False, bf16=True, optim="adamw_8bit"))
# trainer.train()
# model.save_pretrained("tuning/gemma-4-e2b-sakuin-lora") # -> adapters.safetensors ~50MB
