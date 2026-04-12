output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "public_ip" {
  value = try(aws_instance.this.public_ip, null)
}

output "ssh_private_key_file" {
  description = "Dùng với ssh -i (file .pem, đã gitignore)."
  value       = local_file.ssh_private_key.filename
}

# LocalStack Pro map cổng 22 của container EC2 ra một port trên loopback trong pod.
# Tìm dòng kiểu: "Instance ... accessible via SSH ... 127.0.0.1:<PORT>"
output "ssh_hint_kubernetes" {
  description = "Gợi ý lệnh sau khi biết PORT từ log LocalStack."
  value       = <<-EOT
    kubectl logs -n localstack deploy/localstack --tail=400 | grep -iE 'SSH|accessible|${aws_instance.this.id}'

    # Thay PORT bằng số cổng trong log (ví dụ 127.0.0.1:12862 → PORT=12862):
    kubectl port-forward -n localstack deploy/localstack PORT:PORT

    # Chạy từ thư mục guide/localstack/create_ec2 (hoặc chỉnh đường dẫn -i):
    ssh -i ${basename(local_file.ssh_private_key.filename)} -p PORT -o StrictHostKeyChecking=no root@127.0.0.1

    Nếu root không đăng nhập được, thử user ubuntu. Nếu không thấy dòng SSH, thử thêm -c <tên_container> (ví dụ dind) khi kubectl logs.
  EOT
}

# SSH không đi qua Ingress HTTP(S). Muốn dùng hostname (DNS) thì mở TCP trên LB (ingress-nginx tcp-services hoặc Service LoadBalancer).
output "ssh_hint_via_lb_domain" {
  description = "SSH qua domain: cần Service localstack-ssh:22 + TCP publish (không dùng kubectl port-forward)."
  value       = <<-EOT
    1) Đảm bảo cluster có Service localstack-ssh (port 22 → pod LocalStack), ví dụ từ Helm extraDeploy trong apps/playground/localstack/chart/values.yaml.

    2) Với ingress-nginx: thêm vào ConfigMap tcp-services (namespace thường là ingress-nginx), ví dụ cổng ngoài 32222:
       32222: "localstack/localstack-ssh:22"
       Đồng thời mở port 32222 trên Service của ingress controller và cờ --tcp-services-configmap=... (xem tài liệu ingress-nginx TCP).

    3) Trỏ DNS (cùng IP với LB ingress) hoặc dùng hostname hiện có; SSH dùng cổng TCP đã publish:
       ssh -i ${basename(local_file.ssh_private_key.filename)} -p 32222 -o StrictHostKeyChecking=no root@localstack.hoangvu75.space

    Cảnh báo: đừng publish SSH ra Internet công khai nếu không có firewall/VPN/restrict IP.
  EOT
}
